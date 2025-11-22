document.addEventListener("click", function (event) {
  const element = event.target.closest("[data-turbo-confirm]");
  if (!element) return;

  const message = element.getAttribute("data-turbo-confirm");
  if (!message) return;

  const confirmed = window.confirm(message);
  if (!confirmed) {
    event.preventDefault();
    event.stopImmediatePropagation();
  }
});
