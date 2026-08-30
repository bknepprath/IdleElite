const ActivityDocs = (() => {
  const databasePath = "activity-database.json";

  function docsAsset(path) {
    const clean = String(path || "").replace(/^docs\//, "");
    if (!clean || clean.startsWith("../") || clean.startsWith("/") || /^[a-z]+:/i.test(clean)) {
      return clean;
    }
    if (clean.startsWith("assets/")) {
      return "../" + clean;
    }
    return clean;
  }

  async function loadDatabase() {
    const response = await fetch(databasePath);
    if (!response.ok) {
      throw new Error("Unable to load " + databasePath + ": " + response.status);
    }
    const database = await response.json();
    database.skills.forEach(skill => {
      skill.actions = skill.actions.filter(action => action.enabled !== false);
    });
    return database;
  }

  function renderError(target, error) {
    target.innerHTML = '<section class="panel"><strong>Activity data did not load.</strong><p>' +
      String(error.message || error) +
      '</p><p>Serve the docs from the project root over HTTP, for example with <code>python -m http.server</code>.</p></section>';
  }

  return {
    databasePath,
    docsAsset,
    loadDatabase,
    renderError
  };
})();
