#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'time'

ROOT = File.expand_path('..', __dir__)
INDEX_PATH = File.join(ROOT, 'index.html')
REPORT_PATH = File.join(ROOT, 'copy', 'last-run.json')

API_KEY = ENV['AI_API_KEY'] || ENV['OPENAI_API_KEY'] || ENV['OPENROUTER_API_KEY']
BASE_URL = ENV['AI_BASE_URL'] || 'https://openrouter.ai/api/v1'
MODEL = ENV['AI_MODEL'] || 'openai/gpt-4o-mini'

unless File.exist?(INDEX_PATH)
  warn "index.html not found at #{INDEX_PATH}"
  exit 1
end

unless API_KEY && !API_KEY.strip.empty?
  puts 'No AI key found (AI_API_KEY / OPENAI_API_KEY / OPENROUTER_API_KEY). Skipping copy optimization.'
  exit 0
end

html = File.read(INDEX_PATH)

patterns = {
  'hero_h1' => /(<h1[^>]*>)(.*?)(<\/h1>)/m,
  'hero_para_1' => /(<p class="max-w-xl text-lg leading-8 text-slate-600">)(.*?)(<\/p>)/m,
  'hero_para_2' => /(<p class="mt-3 max-w-xl text-base leading-7 text-slate-600">)(.*?)(<\/p>)/m,
  'problem_h2' => /(<h2 class="section-title mt-2 font-bold">)(Most engineers.*?)(<\/h2>)/m,
  'cta_h2' => /(<h2 class="text-3xl font-bold tracking-tight">)(.*?)(<\/h2>)/m,
  'cta_p' => /(<p class="mx-auto mt-3 max-w-2xl text-slate-300">)(.*?)(<\/p>)/m
}

current = {}
patterns.each do |key, pattern|
  match = html.match(pattern)
  if match
    current[key] = match[2].gsub(/\s+/, ' ').strip
  else
    warn "Could not locate #{key} in index.html"
  end
end

if current.empty?
  warn 'No copy blocks found. Exiting.'
  exit 1
end

system_prompt = <<~PROMPT
  You are a conversion copywriter for a UK B2B SaaS landing page.
  Audience: engineering directors, heads of discipline, mentor leads in UK infrastructure and M&E consultancies.
  Product: CPDPath, UK-SPEC aligned workflow for CEng/IEng readiness.

  Rules:
  - Keep claims credible and specific.
  - Keep UK English.
  - No em dashes.
  - Keep output concise and easy to scan.
  - Return valid JSON object only.
PROMPT

user_prompt = {
  task: 'Improve conversion-focused website copy while preserving meaning and section intent.',
  constraints: {
    max_chars: {
      hero_h1: 120,
      hero_para_1: 180,
      hero_para_2: 200,
      problem_h2: 150,
      cta_h2: 90,
      cta_p: 170
    },
    keep_html: true,
    preserve_brand_terms: ['UK-SPEC', 'CEng', 'IEng', 'CPDPath']
  },
  input_copy: current,
  output_format: {
    hero_h1: 'string (can include inline <span> if useful)',
    hero_para_1: 'string',
    hero_para_2: 'string',
    problem_h2: 'string',
    cta_h2: 'string',
    cta_p: 'string'
  }
}

uri = URI.parse("#{BASE_URL}/chat/completions")
req = Net::HTTP::Post.new(uri)
req['Authorization'] = "Bearer #{API_KEY}"
req['Content-Type'] = 'application/json'
req['HTTP-Referer'] = ENV['AI_HTTP_REFERER'] if ENV['AI_HTTP_REFERER']
req['X-Title'] = ENV['AI_APP_NAME'] if ENV['AI_APP_NAME']
req.body = JSON.generate({
  model: MODEL,
  temperature: 0.7,
  messages: [
    { role: 'system', content: system_prompt },
    { role: 'user', content: JSON.pretty_generate(user_prompt) }
  ]
})

res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(req) }
unless res.is_a?(Net::HTTPSuccess)
  warn "AI request failed: #{res.code} #{res.body}"
  exit 1
end

raw = JSON.parse(res.body)
content = raw.dig('choices', 0, 'message', 'content').to_s
json_text = content[/\{.*\}/m]
unless json_text
  warn "Model did not return JSON. Raw content:\n#{content}"
  exit 1
end

suggested = JSON.parse(json_text)
updated_html = html.dup
changes = {}

patterns.each do |key, pattern|
  next unless suggested[key].is_a?(String)

  before = current[key]
  after = suggested[key].gsub(/\s+/, ' ').strip
  next if before.nil? || after.empty? || before == after

  updated_html = updated_html.sub(pattern) do
    "#{$1}#{after}#{$3}"
  end
  changes[key] = { before: before, after: after }
end

Dir.mkdir(File.join(ROOT, 'copy')) unless Dir.exist?(File.join(ROOT, 'copy'))

report = {
  model: MODEL,
  changed_keys: changes.keys,
  changes: changes,
  generated_at_utc: Time.now.utc.iso8601
}
File.write(REPORT_PATH, JSON.pretty_generate(report))

if changes.empty?
  puts 'No copy changes suggested.'
  exit 0
end

File.write(INDEX_PATH, updated_html)
puts "Updated index.html with #{changes.size} copy changes."
