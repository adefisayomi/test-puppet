const express = require("express");
const { scrapeLogic } = require("./scrapeLogic");
const { downloadDocWithType } = require("./puppetter");
const app = express();

const PORT = process.env.PORT || 4000;

app.get("/scrape", (req, res) => {
  scrapeLogic(res);
});

app.post("/resume", async (req, res) => {
  const data = await downloadDocWithType(req.body)
  res.send(data)
});

app.listen(PORT, () => {
  console.log(`Listening on port ${PORT}`);
});
