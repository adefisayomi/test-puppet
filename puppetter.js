require("dotenv").config();
const puppeteer = require("puppeteer");

// Convert millimeters to pixels
const mmToPx = (mm) => mm * 3.7795275591; // 1 mm = 3.7795275591 px

// Size mapping
const pageSizeMap = {
  A1: { width: 594, height: 841 },
  A2: { width: 420, height: 594 },
  A3: { width: 297, height: 420 },
  A4: { width: 210, height: 297 },
  A5: { width: 148, height: 210 },
  A6: { width: 105, height: 148 },
  Letter: { width: 216, height: 279 },
  Legal: { width: 216, height: 356 },
};

// Function to add sleep
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

export const downloadDocWithType = async ({ url, selectedFont, size, type, cookie, isDarkMode }) => {

  const browser = await puppeteer.launch({
    args: [
      "--disable-setuid-sandbox",
      "--no-sandbox",
      "--single-process",
      "--no-zygote",
    ],
    executablePath:
      process.env.NODE_ENV === "production"
        ? process.env.PUPPETEER_EXECUTABLE_PATH
        : puppeteer.executablePath(),
  });

  try {
    if (!url) throw new Error('Invalid request.');

    const page = await browser.newPage();

    // Extract and parse the cookie from the request headers
    const parsedCookies = cookie?.split('; ').map(cookieString => {
      const [name, value] = cookieString.split('=');
      return { 
        name, 
        value, 
        domain: process.env.NODE_ENV === 'development' ? 'localhost' : 'https://qweek.vercel.app' 
      };
    });

    // Set the cookie(s) for authentication if available
    if (parsedCookies) {
      await page.setCookie(...parsedCookies);
    }

    // Go to the page and wait for content to load
    await page.goto(url, { waitUntil: 'networkidle0' });

    // Inject CSS styles (either dark or light mode)
    if (isDarkMode) {
      await page.evaluate(() => {
        document.body.classList.add('dark'); // Apply dark mode
      });
    } else {
      await page.evaluate(() => {
        document.body.classList.remove('dark'); // Use default (light) mode
      });
    }

    // Inject the selected font into the page
    if (selectedFont) {
      await page.evaluate(async (font) => {
        const fontLink = document.createElement('link');
        fontLink.rel = 'stylesheet';
        fontLink.href = `https://fonts.googleapis.com/css2?family=${font.replace(/\s/g, '+')}&display=swap`;
        document.head.appendChild(fontLink);

        const fontStyle = document.createElement('style');
        fontStyle.textContent = `
          #resume_container {
            font-family: '${font}', sans-serif !important;
          }
        `;
        document.head.appendChild(fontStyle);

        // Ensure the font is fully loaded
        await document.fonts.load(`1em ${font}`);
        await document.fonts.ready;
      }, selectedFont);
    }

    // Wait for the font to render and stabilize
    await sleep(2000);

    // Get the bounding box of the resume container
    const boundingBox = await page.evaluate(() => {
      const element = document.querySelector('#resume_container');
      if (!element) return null;
      const { offsetWidth, offsetHeight } = element;
      return { width: offsetWidth, height: offsetHeight };
    });

    if (!boundingBox) {
      throw new Error('Element with id #resume_container not found');
    }

    // Determine the size dimensions
    const sizeDimensions = size ? pageSizeMap[size] : null;
    const width = sizeDimensions ? mmToPx(sizeDimensions.width) : boundingBox.width;
    const height = sizeDimensions ? mmToPx(sizeDimensions.height) : boundingBox.height;

    // Generate the requested file type
    let file;
    switch (type) {
      case 'pdf':
        file = await page.pdf({
          printBackground: isDarkMode,
          width: `${width}px`,
          height: `${height}px`,
          margin: { top: '0px', right: '0px', bottom: '0px', left: '0px' },
        });
        break;
      case 'png':
      case 'jpeg':
        file = await page.screenshot({
          fullPage: true,
          type: type,
          clip: { x: 0, y: 0, width, height },
        });
        break;
      case 'docx':
        throw new Error('DOCX generation is not yet implemented.');
      default:
        throw new Error('Unsupported file type');
    }

    return {
      success: true, 
      message: null,
      data: file
    };
  } catch (err) {
    return { success: false, message: err.message };
  } finally {
    if (browser) await browser.close();
  }
};
