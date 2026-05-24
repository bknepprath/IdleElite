const ActivityDocs = (() => {
  const databasePath = "activity-database.json";

  function docsAsset(path) {
    return String(path || "").replace(/^docs\//, "");
  }

  function formatSeconds(value) {
    const seconds = Number(value);
    return seconds.toFixed(seconds < 10 ? 1 : 0) + "s";
  }

  function formatPercent(value) {
    return Number(value).toFixed(0) + "%";
  }

  function embeddedDatabase() {
    const database = globalThis.IDLE_ELITE_ACTIVITY_DATABASE;
    return database ? JSON.parse(JSON.stringify(database)) : null;
  }

  async function loadDatabase() {
    try {
      const response = await fetch(databasePath);
      if (!response.ok) {
        throw new Error("Unable to load " + databasePath + ": " + response.status);
      }
      return response.json();
    } catch (error) {
      const database = embeddedDatabase();
      if (database) return database;
      throw error;
    }
  }

  function createSkillState(skillData, freshSkillState) {
    return Object.fromEntries(skillData.map(skill => [skill.id, freshSkillState()]));
  }

  function createMasteryState(skillData) {
    return Object.fromEntries(skillData.flatMap(skill => skill.actions.map(action => [
      skill.id + ":" + action.id,
      { xp: 0, level: 0 }
    ])));
  }

  function databaseSkillData(database) {
    return database.skills.map(skill => ({
      id: skill.id,
      name: skill.name,
      verb: skill.verb,
      identity: skill.identity,
      icon: docsAsset(skill.icon),
      actions: skill.actions.map(action => ({
        id: action.id,
        name: action.name,
        unlock: action.unlock,
        seconds: action.seconds,
        xp: action.xp,
        stamina: action.stamina,
        success: action.success,
        art: docsAsset(action.art),
        bg: docsAsset(action.background)
      }))
    }));
  }

  function renderError(target, error) {
    target.innerHTML = '<section class="panel"><strong>Activity data did not load.</strong><p>' +
      String(error.message || error) +
      '</p><p>Serve the docs from the project root or include activity-database-data.js before activity-docs.js.</p></section>';
  }

  return {
    databasePath,
    docsAsset,
    formatSeconds,
    formatPercent,
    embeddedDatabase,
    loadDatabase,
    createSkillState,
    createMasteryState,
    databaseSkillData,
    renderError
  };
})();
