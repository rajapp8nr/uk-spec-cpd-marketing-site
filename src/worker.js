export default {
  async fetch(request, env) {
    // Serve static assets from the repository root via ASSETS binding.
    return env.ASSETS.fetch(request)
  },
}
