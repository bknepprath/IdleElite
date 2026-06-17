(() => {
  const groups = [
    {
      label: "Core",
      links: [
        { href: "planning-system.html", label: "Rebuild Board", description: "New module columns" },
        { href: "module-type-dictionary.html", label: "Type Dictionary", description: "Module meanings" },
        { href: "ui-navigation-controls-plan.html", label: "UI Controls", description: "Navigation dock plan" },
        { href: "activity-database.html", label: "Activity Data", description: "Numbers and rewards" },
        { href: "idle-elite-action-review.html", label: "Module Review", description: "All cards visually" }
      ]
    },
    {
      label: "References",
      links: [
        { href: "idle-elite-app-mock.html", label: "Current UI", description: "Screen map" },
        { href: "passive-module-mock.html", label: "Passive Logs", description: "Collect module" },
        { href: "fishing-rework-brainstorm.html", label: "Fishing Status", description: "Live fishing setup" }
      ]
    },
    {
      label: "Storage",
      links: [
        { href: "archive/index.html", label: "Archive", description: "Old plans and mocks" }
      ]
    }
  ];

  function currentKey() {
    const path = (location.pathname || "").split("/").pop() || "";
    const view = new URLSearchParams(location.search).get("view");
    return path + (view ? "?" + view : "");
  }

  function linkKey(href) {
    const url = new URL(href, location.href);
    const path = url.pathname.split("/").pop() || "";
    const view = url.searchParams.get("view");
    return path + (view ? "?" + view : "");
  }

  function renderNav(container) {
    const here = currentKey();
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
        if (item.description) {
          const desc = document.createElement("span");
          desc.className = "docs-nav-link-desc";
          desc.textContent = item.description;
          a.appendChild(desc);
        }
        if (linkKey(item.href) === here) {
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
