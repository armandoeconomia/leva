import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "messages", "input", "error", "submit"]

  connect() {
    this.open = false
    this.chatHistory = []
    this.registerInitialMessage()
  }

  toggle(event) {
    event.preventDefault()
    this.open = !this.open
    this.panelTarget.classList.toggle("is-open", this.open)
    if (this.open) {
      this.inputTarget.focus()
    }
  }

  send(event) {
    event.preventDefault()
    const content = this.inputTarget.value.trim()
    if (!content) {
      this.showError("Escribe tu consulta para que podamos ayudarte.")
      return
    }

    this.showError(null)
    this.appendMessage("Tú", content, "user")
    this.inputTarget.value = ""
    const historySnapshot = this.historyPayload()
    this.requestAssistant(content, historySnapshot)
  }

  requestAssistant(content, history) {
    this.setLoading(true)
    fetch("/public/assistant/message", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ chat: { content, history } })
    })
      .then(async (response) => {
        const data = await response.json()
        return { ok: response.ok, data }
      })
      .then(({ ok, data }) => {
        this.setLoading(false)
        if (!ok) {
          this.showError(data.error || "No se pudo completar la solicitud.")
          return
        }
        this.chatHistory.push({ role: "user", content })
        this.chatHistory.push({ role: "assistant", content: data.reply })
        this.appendMessage("Asistente LEVA", data.reply, "assistant")
      })
      .catch(() => {
        this.setLoading(false)
        this.showError("No pude conectarme con el asistente. Inténtalo nuevamente.")
      })
  }

  appendMessage(author, text, type) {
    const wrapper = document.createElement("div")
    wrapper.className = `landing-chat__message landing-chat__message--${type}`
    wrapper.innerHTML = `
      <p class="landing-chat__message-author mb-1">${author}</p>
      <p class="landing-chat__message-body mb-0">${this.escapeHtml(text).replace(/\n/g, "<br>")}</p>
    `
    this.messagesTarget.appendChild(wrapper)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  registerInitialMessage() {
    const initial = this.messagesTarget.querySelector("[data-initial-message='true']")
    if (!initial) return
    const baseContent = initial.dataset.message || initial.innerText.trim()
    if (baseContent) {
      this.chatHistory.push({ role: "assistant", content: baseContent })
    }
  }

  historyPayload() {
    return this.chatHistory.map((entry) => ({ role: entry.role, content: entry.content }))
  }

  showError(message) {
    this.errorTarget.textContent = message || ""
  }

  setLoading(state) {
    this.submitTarget.disabled = state
    this.submitTarget.textContent = state ? "Consultando..." : "Preguntar al asistente"
  }

  get csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }

  escapeHtml(string) {
    return string
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;")
  }
}
