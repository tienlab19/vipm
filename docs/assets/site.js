(() => {
  const supported = new Set(["en", "vi"]);
  const saved = localStorage.getItem("pspoprep-language");
  const browserLanguage = navigator.language.toLowerCase().startsWith("vi") ? "vi" : "en";
  const initialLanguage = supported.has(saved) ? saved : browserLanguage;

  function setLanguage(language) {
    if (!supported.has(language)) return;

    document.documentElement.lang = language;
    document.body.dataset.language = language;
    localStorage.setItem("pspoprep-language", language);

    document.querySelectorAll("[data-language-button]").forEach((button) => {
      const active = button.dataset.languageButton === language;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-pressed", String(active));
    });

    const title = document.querySelector(`[data-page-title-${language}]`)?.getAttribute(`data-page-title-${language}`);
    if (title) document.title = title;

    document.querySelectorAll("[data-anchor-en]").forEach((link) => {
      link.href = link.dataset[`anchor${language === "en" ? "En" : "Vi"}`];
    });
  }

  document.querySelectorAll("[data-language-button]").forEach((button) => {
    button.addEventListener("click", () => setLanguage(button.dataset.languageButton));
  });

  setLanguage(initialLanguage);
})();
