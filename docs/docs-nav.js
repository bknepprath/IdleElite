(() => {
  const groups = [
    {
      label: "Product",
      links: [
        { href: "idle-elite-prd.html", label: "Godot PRD" },
        { href: "activity-database.html", label: "Activity DB" }
      ]
    },
    {
      label: "Godot UI refs",
      links: [
        { href: "idle-elite-app-mock.html", label: "Current UI" },
        { href: "player-hub-mock.html", label: "Player hub" },
        { href: "idle-elite-action-review.html", label: "Action review" },
        { href: "stamina-gauge-mock.html", label: "Stamina rules" },
        { href: "passive-module-mock.html", label: "Collect module" }
      ]
    },
    {
      label: "Fishing",
      links: [
        { href: "fishing-rework-brainstorm.html", label: "Current fishing" }
      ]
    },
    {
      label: "Tuning tools",
      links: [
        { href: "log-collect-1-stats.html", label: "Log stats" },
        { href: "xp-sfx-audition.html", label: "SFX audition" }
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
        a.textContent = item.label;
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
