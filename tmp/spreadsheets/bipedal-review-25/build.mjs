import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const projectRoot = "C:/Users/bknep/Documents/Idle Slop 1";
const imageDir = path.join(projectRoot, "output/imagegen/bipedal-review-25");
const outputDir = path.join(projectRoot, "outputs/019f7886-654a-7562-a0fe-e98812ab2f03");
const previewPath = path.join(projectRoot, "tmp/spreadsheets/bipedal-review-25/review-preview.png");
const outputPath = path.join(outputDir, "bipedal-character-review.xlsx");

const characters = [
  ["01", "Sword Recruit", "Average build · short sword · rust spiked hair", "01-sword-recruit.png"],
  ["02", "Axe Runner", "Lean running pose · broad axe · orange topknot", "02-axe-runner.png"],
  ["03", "Archer", "Balanced stance · curved bow · swept red hair", "03-archer.png"],
  ["04", "Spear Scout", "Tall narrow build · diagonal spear · blond mohawk", "04-spear-scout.png"],
  ["05", "Hammer Guard", "Wide braced build · square hammer · bowl cut", "05-hammer-guard.png"],
  ["06", "Healer", "Soft upright shape · crooked staff · blond bob", "06-healer.png"],
  ["07", "Ember Mage", "Narrow hunched shape · disk staff · black puff hair", "07-ember-mage.png"],
  ["08", "Grove Druid", "Round poncho shape · forked staff · leaf-like hair", "08-grove-druid.png"],
  ["09", "Knife Rogue", "Low crouch · curved knife · swept black hair", "09-knife-rogue.png"],
  ["10", "Shield Bearer", "Broad defensive stance · round shield · auburn bob", "10-shield-bearer.png"],
  ["11", "Club Brute", "Extreme pear shape · dragging club · tiny hair tuft", "11-club-brute.png"],
  ["12", "Crossbowman", "Square body · horizontal crossbow · chestnut fringe", "12-crossbowman.png"],
  ["13", "Flail Fighter", "Backward lean · smooth ball flail · dark bob", "13-flail-fighter.png"],
  ["14", "Lantern Keeper", "Thin walking pose · box lantern · blond cap hair", "14-lantern-keeper.png"],
  ["15", "Miner", "Compact worker · pickaxe · orange fringe and soft cap", "15-miner.png"],
  ["16", "Field Worker", "Lean side step · pitchfork · straw swept hair", "16-field-worker.png"],
  ["17", "Harpooner", "Broad pulling pose · harpoon · black rear knot", "17-harpooner.png"],
  ["18", "Staff Monk", "Balanced upright pose · horizontal staff · hair bun", "18-staff-monk.png"],
  ["19", "Duelist", "Long forward lunge · rapier · black ponytail", "19-duelist.png"],
  ["20", "Banner Carrier", "Upright march · plain banner · red curls", "20-banner-carrier.png"],
  ["21", "Sling Scout", "Twisted action pose · slingshot · blond crop", "21-sling-scout.png"],
  ["22", "Alchemist", "Round careful pose · opaque flask · auburn curls", "22-alchemist.png"],
  ["23", "Torch Bearer", "Thin cautious pose · flat flame torch · black bob", "23-torch-bearer.png"],
  ["24", "Shovel Worker", "Low sturdy worker · shovel · blond side knots", "24-shovel-worker.png"],
  ["25", "Minstrel", "Rounded playful pose · lute · dark-red waves", "25-minstrel.png"],
];

const workbook = Workbook.create();
const sheet = workbook.worksheets.add("Character Review");
sheet.showGridLines = false;
sheet.freezePanes.freezeRows(5);
sheet.freezePanes.freezeColumns(2);

sheet.getRange("A1:H1").merge();
sheet.getRange("A1").values = [["Bipedal Character Review — 25 Variations"]];
sheet.getRange("A1:H1").format = {
  fill: "#244C33",
  font: { bold: true, color: "#FFFFFF" },
  horizontalAlignment: "left",
  verticalAlignment: "center",
};

sheet.getRange("A2:H2").merge();
sheet.getRange("A2").values = [["Use the Like and Dislike dropdowns to switch ☐ to ☑. Add notes about proportions, pose, hair, palette, outline, or equipment."]];
sheet.getRange("A2:H2").format = {
  fill: "#E8EFE8",
  font: { color: "#33443A" },
  horizontalAlignment: "left",
  verticalAlignment: "center",
  wrapText: true,
};

sheet.getRange("A3:H3").values = [["Liked", null, "Disliked", null, "Unreviewed", null, "Conflicts", null]];
sheet.getRange("B3").formulas = [["=COUNTIF(H6:H30,\"LIKE\")"]];
sheet.getRange("D3").formulas = [["=COUNTIF(H6:H30,\"DISLIKE\")"]];
sheet.getRange("F3").formulas = [["=COUNTIF(H6:H30,\"UNREVIEWED\")"]];
sheet.getRange("H3").formulas = [["=COUNTIF(H6:H30,\"CONFLICT\")"]];
sheet.getRange("A3:H3").format = {
  fill: "#F4F1E8",
  font: { bold: true, color: "#3A463F" },
  horizontalAlignment: "center",
  verticalAlignment: "center",
  borders: { preset: "outside", style: "thin", color: "#CBD5CC" },
};
for (const cell of ["B3", "D3", "F3", "H3"]) {
  sheet.getRange(cell).format = {
    fill: "#FFFFFF",
    font: { bold: true, color: "#244C33" },
    horizontalAlignment: "center",
  };
}

sheet.getRange("A5:H5").values = [["ID", "Preview", "Character", "Variation", "Like", "Dislike", "Notes", "Status"]];
sheet.getRange("A5:H5").format = {
  fill: "#4F6A45",
  font: { bold: true, color: "#FFFFFF" },
  horizontalAlignment: "center",
  verticalAlignment: "center",
  borders: { bottom: { style: "medium", color: "#244C33" } },
};

const bodyValues = characters.map(([id, name, variation]) => [id, null, name, variation, "☐", "☐", "", null]);
sheet.getRange("A6:H30").values = bodyValues;
sheet.getRange("H6").formulas = [["=IF(AND(E6=\"☑\",F6=\"☑\"),\"CONFLICT\",IF(E6=\"☑\",\"LIKE\",IF(F6=\"☑\",\"DISLIKE\",\"UNREVIEWED\")))"]];
sheet.getRange("H6:H30").fillDown();

sheet.getRange("A6:H30").format = {
  fill: "#FFFFFF",
  font: { color: "#26342C" },
  verticalAlignment: "center",
  borders: {
    insideHorizontal: { style: "thin", color: "#D8DED6" },
    bottom: { style: "thin", color: "#B8C3B9" },
  },
};
sheet.getRange("A6:A30").format.horizontalAlignment = "center";
sheet.getRange("B6:B30").format.fill = "#F4F1E8";
sheet.getRange("C6:C30").format.font = { bold: true, color: "#244C33" };
sheet.getRange("D6:D30").format.wrapText = true;
sheet.getRange("E6:F30").format = {
  font: { color: "#244C33" },
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
sheet.getRange("G6:G30").format = {
  fill: "#FFFDF8",
  font: { color: "#3C433F" },
  verticalAlignment: "top",
  wrapText: true,
};
sheet.getRange("H6:H30").format = {
  font: { bold: true, color: "#66736A" },
  horizontalAlignment: "center",
};

sheet.getRange("E6:E30").dataValidation = { rule: { type: "list", values: ["☐", "☑"] } };
sheet.getRange("F6:F30").dataValidation = { rule: { type: "list", values: ["☐", "☑"] } };

const rows = sheet.getRange("A6:H30");
rows.conditionalFormats.addCustom('=$E6="☑"', { fill: "#EAF5EA" });
rows.conditionalFormats.addCustom('=$F6="☑"', { fill: "#FBEDEC" });
rows.conditionalFormats.addCustom('=AND($E6="☑",$F6="☑")', { fill: "#FFF2CC" });
sheet.getRange("H6:H30").conditionalFormats.add("containsText", { text: "LIKE", format: { fill: "#D9EED9", font: { bold: true, color: "#235A2D" } } });
sheet.getRange("H6:H30").conditionalFormats.add("containsText", { text: "DISLIKE", format: { fill: "#F6DAD7", font: { bold: true, color: "#8A2E2A" } } });
sheet.getRange("H6:H30").conditionalFormats.add("containsText", { text: "CONFLICT", format: { fill: "#FFE7A8", font: { bold: true, color: "#7A4C00" } } });

sheet.getRange("A1:A30").format.columnWidthPx = 52;
sheet.getRange("B1:B30").format.columnWidthPx = 126;
sheet.getRange("C1:C30").format.columnWidthPx = 150;
sheet.getRange("D1:D30").format.columnWidthPx = 270;
sheet.getRange("E1:E30").format.columnWidthPx = 86;
sheet.getRange("F1:F30").format.columnWidthPx = 86;
sheet.getRange("G1:G30").format.columnWidthPx = 250;
sheet.getRange("H1:H30").format.columnWidthPx = 95;
sheet.getRange("A1:H1").format.rowHeightPx = 42;
sheet.getRange("A2:H2").format.rowHeightPx = 42;
sheet.getRange("A3:H3").format.rowHeightPx = 34;
sheet.getRange("A4:H4").format.rowHeightPx = 12;
sheet.getRange("A5:H5").format.rowHeightPx = 30;
sheet.getRange("A6:H30").format.rowHeightPx = 124;

for (let i = 0; i < characters.length; i += 1) {
  const file = characters[i][3];
  const bytes = await fs.readFile(path.join(imageDir, file));
  sheet.images.add({
    dataUrl: `data:image/png;base64,${bytes.toString("base64")}`,
    anchor: {
      from: { row: 5 + i, col: 1, rowOffsetPx: 7, colOffsetPx: 8 },
      extent: { widthPx: 110, heightPx: 110 },
    },
  });
}

const check = await workbook.inspect({
  kind: "table",
  range: "'Character Review'!A1:H30",
  include: "values,formulas",
  tableMaxRows: 30,
  tableMaxCols: 8,
  maxChars: 10000,
});
console.log(check.ndjson);

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 100 },
  summary: "final formula error scan",
});
console.log(errors.ndjson);

const preview = await workbook.render({
  sheetName: "Character Review",
  range: "A1:H30",
  scale: 0.65,
  format: "png",
});
await fs.writeFile(previewPath, new Uint8Array(await preview.arrayBuffer()));

await fs.mkdir(outputDir, { recursive: true });
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log(JSON.stringify({ outputPath, previewPath }));
