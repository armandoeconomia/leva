RubyLLM.configure do |config|
  config.logger = Rails.logger
  config.default_model = ENV.fetch("RUBYLLM_MODEL", "gpt-4.1-mini")
  config.request_timeout = ENV.fetch("RUBYLLM_TIMEOUT", 120).to_i
  config.max_retries = 2

  if ENV["OPENAI_API_KEY"].present?
    config.openai_api_key = ENV["OPENAI_API_KEY"]
    config.openai_organization_id = ENV["OPENAI_ORG_ID"] if ENV["OPENAI_ORG_ID"].present?
  end

  config.openrouter_api_key = ENV["OPENROUTER_API_KEY"] if ENV["OPENROUTER_API_KEY"].present?
  config.gemini_api_key = ENV["GEMINI_API_KEY"] if ENV["GEMINI_API_KEY"].present?
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"] if ENV["ANTHROPIC_API_KEY"].present?
end
