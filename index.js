const express = require("express");
const cors = require("cors"); // Import cors
const { downloadPdf } = require("./puppetter");
const cookieParser = require("cookie-parser");
const { scrapeLogic } = require("./scrapeLogic");

const app = express();
const PORT = process.env.PORT || 4000;

// Enable CORS for requests from localhost:3000
app.use(cors({
  origin: ["http://localhost:3000", "https://qweek.vercel.app", "https://puppet-3wt0.onrender.com"], // Allow requests from localhost:3000
  methods: "GET,POST", // Allow specific methods
  credentials: true // Allow cookies or credentials to be included
}));
app.use(cookieParser());

// Middleware to parse JSON bodies
app.use(express.json());

app.post('/scrape', async (req, res) => {
  const data = await scrapeLogic()
  console.log(data)
  res.send(data)
})

app.post('/resume', async (req, res) => {
    const { url, selectedFont, size, isDarkMode } = req.body;
    const result = await downloadPdf({ url, selectedFont, size, isDarkMode })
    res.send(result)
});

app.listen(PORT, () => {
  console.log(`Listening on port ${PORT}`);
});