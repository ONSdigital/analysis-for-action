### **Preparing Geographic Data (The merge\_layers.R Tool)**

To keep the application fast and organized, spatial data for each country must be bundled into a single file (a Geopackage) before the app can use it. Follow these exact steps to process your raw geographic files and configure them for the application.

**Step 1: Prepare Your Raw Files**

* Download the individual geographic boundary files (such as .gpkg or .shp files) for the country you want to add.  
* You will typically need one file for each administrative level (e.g., one for provinces, one for departments).  
* Place all of these raw files into the raw\_data/ folder located in the application's root directory.

**Step 2: Run the Preparation Tool** Because this tool asks you for input, it must be run in the console, not just sourced.

* Open the project in RStudio.  
* Open the file located at data\_prep/merge\_layers.R.  
* Highlight all the code in that file and press **Ctrl \+ Enter** (or **Cmd \+ Enter** on Mac) to send it to the console.  
* *(Alternatively, advanced users can open a terminal, navigate to the project folder, and run Rscript data\_prep/merge\_layers.R)*.

**Step 3: Follow the On-Screen Prompts** The console will now ask you a series of questions:

* **Country Name:** Type the name of the country exactly as you want it to appear in the app (e.g., Argentina) and press Enter.  
* **Level Name:** Type the name of the highest geographic level (e.g., province) and press Enter.  
* **File Path:** Type the exact path to the corresponding raw file you placed in Step 1 (e.g., raw\_data/prov\_argentina.gpkg) and press Enter.  
* **Repeat:** The tool will ask for the next level down (e.g., department). Provide the name and file path.  
* **Finish:** Once you have entered all your levels, simply press **Enter** without typing anything when asked for the next level name.  
* The script will process the files and create a single, consolidated file named YourCountry.gpkg inside the raw\_data/ folder.

**Step 4: Update the Configuration** Now that the data is ready, you must tell the application how to read it.

* Open the config.json file located in the root directory.  
* Add a new block for your country.  
* Ensure the layer\_name fields exactly match the level names you typed into the console in Step 3\.  
* Ensure the parent\_col fields correctly link the lower levels to their parent levels so the application's dropdown menus can filter correctly.

**Step 5: Restart and Deploy**

* Restart your R session and run the Shiny application.  
* The new country will automatically appear in the dropdown menus.  
* If you are preparing this for end-users, you can now safely bundle the application into a standalone .exe using Inno Setup.  
* The Inno Setup compiler will package your newly created YourCountry.gpkg and the updated config.json, providing a seamless experience for the final user.

