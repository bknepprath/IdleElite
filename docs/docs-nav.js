(() => {
  const groups = [
    {
      label: "Core",
      links: [
        { href: "planning-system.md", label: "Planning Board" },
        { href: "module-type-dictionary.html", label: "Type Dictionary" },
        { href: "ui-navigation-controls-plan.html", label: "UI Controls" },
        { href: "activity-database.html", label: "Activity Data" }
      ]
    },
    {
      label: "References",
      links: [
        { href: "fishing-rework-brainstorm.html", label: "Fishing Status" }
      ]
    }
  ];

  function pageKey(href) {
    return new URL(href, location.href).pathname.split("/").pop() || "";
  }

  function renderNav(container) {
    const here = pageKey(location.href);
    container.classList.add("docs-nav");
    container.setAttribute("aria-label", "Docs");
    container.replaceChildren();

    groups.forEach((group) => {
      const wrap = document.createElement("div");
      wrap.className = "docs-nav-group";

      const label = document.createElement("p");
      label.className = "docs-nav-label";
      label.textContent = group.label;
      wrap.appendChild(label);

      const links = document.createElement("div");
      links.className = "docs-nav-links";

      group.links.forEach((item) => {
        const a = document.createElement("a");
        a.className = "docs-nav-link";
        a.href = item.href;
        const linkTitle = document.createElement("span");
        linkTitle.className = "docs-nav-link-title";
        linkTitle.textContent = item.label;
        a.appendChild(linkTitle);
        if (pageKey(item.href) === here) {
          a.classList.add("is-current");
          a.setAttribute("aria-current", "page");
        }
        links.appendChild(a);
      });

      wrap.appendChild(links);
      container.appendChild(wrap);
    });
  }

  document.querySelectorAll("[data-docs-nav]").forEach(renderNav);
})();
