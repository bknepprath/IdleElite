import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const projectRoot = "C:/Users/bknep/Documents/Idle Slop 1";
const imageDir = path.join(projectRoot, "output/imagegen/quadruped-review-10");
const outputDir = path.join(projectRoot, "outputs/019f7886-654a-7562-a0fe-e98812ab2f03");
const workDir = path.join(projectRoot, "tmp/spreadsheets/quadruped-review-10");
const previewPath = path.join(workDir, "review-preview.png");
const outputPath = path.join(outputDir, "quadruped-character-review.xlsx");
const unchecked = "\u2610";
const checked = "\u2611";

const characters = [
  ["01", "Wolf Scout", "Low canine \u00B7 oversized ears and tail \u00B7 simple collar", "01-wolf-scout.png"],
  ["02", "Armored Boar", "Heavy boar \u00B7 giant tusks \u00B7 armor and saddle", "02-armored-boar.png"],
  ["03", "Forest Stag", "Upright stag \u00B7 giant antlers \u00B7 leaf mantle", "03-forest-stag.png"],
  ["04", "Stone Ram", "Blocky ram \u00B7 stone plates \u00B7 curled horns", "04-stone-ram.png"],
  ["05", "Swamp Lizard", "Long low lizard \u00B7 back plates \u00B7 leaf tail", "05-swamp-lizard.png"],
  ["06", "Frost Yak", "Heavy yak \u00B7 single fringe mass \u00B7 wide horns", "06-frost-yak.png"],
  ["07", "Shadow Panther", "Low feline \u00B7 long curved tail \u00B7 shoulder wrap", "07-shadow-panther.png"],
  ["08", "Hyena Raider", "Sloped hyena \u00B7 large ears \u00B7 mane and pouch", "08-hyena-raider.png"],
  ["09", "Shellback Tortoise", "Wide tortoise \u00B7 huge shell \u00B7 fortified harness", "09-shellback-tortoise.png"],
  ["10", "Ember Salamander", "Long salamander \u00B7 three back fins \u00B7 flame tail", "10-ember-salamander.png"],
];

function pngSize(bytes) {
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
}

const workbook = Workbook.create();
const sheet = workbook.worksheets.add("Quadruped Review");
sheet.showGridLines = false;
sheet.freezePanes.freezeRows(5);
sheet.freezePanes.freezeColumns(2);

sheet.getRange("A1:H1").merge();
sheet.getRange("A1").values = [["Quadruped Character Review \u2014 10 Variations"]];
sheet.getRange("A1:H1").format = {
  fill: "#244C33",
  font: { bold: true, color: "#FFFFFF" },
  horizontalAlignment: "left",
  verticalAlignment: "center",
};

sheet.getRange("A2:H2").merge();
sheet.getRange("A2").values = [[`Use the Like and Dislike dropdowns to switch ${unchecked} to ${checked}. Add notes about silhouette, proportions, feature size, outline, palette, or shading.`]];
sheet.getRange("A2:H2").format = {
  fill: "#E8EFE8",
  font: { color: "#33443A" },
  horizontalAlignment: "left",
  verticalAlignment: "center",
  wrapText: true,
};

sheet.getRange("A3:H3").values = [["Liked", null, "Disliked", null, "Unreviewed", null, "Conflicts", null]];
sheet.getRange("B3").formulas = [["=COUNTIF(H6:H15,\"LIKE\")"]];
sheet.getRange("D3").formulas = [["=COUNTIF(H6:H15,\"DISLIKE\")"]];
sheet.getRange("F3").formulas = [["=COUNTIF(H6:H15,\"UNREVIEWED\")"]];
sheet.getRange("H3").formulas = [["=COUNTIF(H6:H15,\"CONFLICT\")"]];
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

sheet.getRange("A5:H5").values = [["ID", "Preview", "Quadruped", "Variation", "Like", "Dislike", "Notes", "Status"]];
sheet.getRange("A5:H5").format = {
  fill: "#4F6A45",
  font: { bold: true, color: "#FFFFFF" },
  horizontalAlignment: "center",
  verticalAlignment: "center",
  borders: { bottom: { style: "medium", color: "#244C33" } },
};

sheet.getRange("A6:H15").values = characters.map(([id, name, variation]) => [id, null, name, variation, unchecked, unchecked, "", null]);
sheet.getRange("H6").formulas = [[`=IF(AND(E6="${checked}",F6="${checked}"),"CONFLICT",IF(E6="${checked}","LIKE",IF(F6="${checked}","DISLIKE","UNREVIEWED")))`]];
sheet.getRange("H6:H15").fillDown();

sheet.getRange("A6:H15").format = {
  fill: "#FFFFFF",
  font: { color: "#26342C" },
  verticalAlignment: "center",
  borders: {
    insideHorizontal: { style: "thin", color: "#D8DED6" },
    bottom: { style: "thin", color: "#B8C3B9" },
  },
};
sheet.getRange("A6:A15").format.horizontalAlignment = "center";
sheet.getRange("B6:B15").format.fill = "#F4F1E8";
sheet.getRange("C6:C15").format.font = { bold: true, color: "#244C33" };
sheet.getRange("D6:D15").format.wrapText = true;
sheet.getRange("E6:F15").format = { font: { color: "#244C33" }, horizontalAlignment: "center", verticalAlignment: "center" };
sheet.getRange("G6:G15").format = { fill: "#FFFDF8", font: { color: "#3C433F" }, verticalAlignment: "top", wrapText: true };
sheet.getRange("H6:H15").format = { font: { bold: true, color: "#66736A" }, horizontalAlignment: "center" };

sheet.getRange("E6:E15").dataValidation = { rule: { type: "list", values: [unchecked, checked] } };
sheet.getRange("F6:F15").dataValidation = { rule: { type: "list", values: [unchecked, checked] } };

const rows = sheet.getRange("A6:H15");
rows.conditionalFormats.addCustom(`=$E6="${checked}"`, { fill: "#EAF5EA" });
rows.conditionalFormats.addCustom(`=$F6="${checked}"`, { fill: "#FBEDEC" });
rows.conditionalFormats.addCustom(`=AND($E6="${checked}",$F6="${checked}")`, { fill: "#FFF2CC" });
sheet.getRange("H6:H15").conditionalFormats.add("containsText", { text: "LIKE", format: { fill: "#D9EED9", font: { bold: true, color: "#235A2D" } } });
sheet.getRange("H6:H15").conditionalFormats.add("containsText", { text: "DISLIKE", format: { fill: "#F6DAD7", font: { bold: true, color: "#8A2E2A" } } });
sheet.getRange("H6:H15").conditionalFormats.add("containsText", { text: "CONFLICT", format: { fill: "#FFE7A8", font: { bold: true, color: "#7A4C00" } } });

for (const [range, width] of [["A1:A15", 52], ["B1:B15", 150], ["C1:C15", 158], ["D1:D15", 270], ["E1:E15", 86], ["F1:F15", 86], ["G1:G15", 250], ["H1:H15", 95]]) {
  sheet.getRange(range).format.columnWidthPx = width;
}
sheet.getRange("A1:H1").format.rowHeightPx = 42;
sheet.getRange("A2:H2").format.rowHeightPx = 42;
sheet.getRange("A3:H3").format.rowHeightPx = 34;
sheet.getRange("A4:H4").format.rowHeightPx = 12;
sheet.getRange("A5:H5").format.rowHeightPx = 30;
sheet.getRange("A6:H15").format.rowHeightPx = 128;

for (let index = 0; index < characters.length; index += 1) {
  const bytes = await fs.readFile(path.join(imageDir, characters[index][3]));
  const { width, height } = pngSize(bytes);
  const scale = Math.min(132 / width, 112 / height);
  const widthPx = Math.round(width * scale);
  const heightPx = Math.round(height * scale);
  sheet.images.add({
    dataUrl: `data:image/png;base64,${bytes.toString("base64")}`,
    anchor: {
      from: { row: 5 + index, col: 1, rowOffsetPx: Math.round((128 - heightPx) / 2), colOffsetPx: Math.round((150 - widthPx) / 2) },
      extent: { widthPx, heightPx },
    },
  });
}

console.log((await workbook.inspect({ kind: "table", range: "'Quadruped Review'!A1:H15", include: "values,formulas", tableMaxRows: 15, tableMaxCols: 8, maxChars: 7000 })).ndjson);
console.log((await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A", options: { useRegex: true, maxResults: 100 }, summary: "final formula error scan" })).ndjson);

const preview = await workbook.render({ sheetName: "Quadruped Review", range: "A1:H15", scale: 0.75, format: "png" });
await fs.writeFile(previewPath, new Uint8Array(await preview.arrayBuffer()));
await fs.mkdir(outputDir, { recursive: true });
await (await SpreadsheetFile.exportXlsx(workbook)).save(outputPath);
console.log(JSON.stringify({ outputPath, previewPath, imageCount: characters.length }));
