# Famous-Paintings-by-MEXWELL
SQL and Python

## Data
This dataset is called Famous Paintings by MEXWELL.

Link           : https://www.kaggle.com/datasets/mexwell/famous-paintings (3 Months Ago)

Original Data  : https://data.world/atlas-query/paintings (Last Year)

This dataset has 8 interconnected tables:
- artist.csv contains information about the artist
- canvas_size.csv contains information about canvas size
- image_link.csv contains information about image link to each painting (link not working)
- museum.csv contains information about the museum
- museum_hours.csv contains information the museum schedule
- product_size.csv contains information about the price of each painting
- subject.csv contains information about the subject of each painting
- work.csv contains overall information of each painting
  
## Import Data
Importing dataset using Pandas Dataframe to Microsoft SQL Server in Python.

Tools :
- Jupyter Notebook 6.5.4
- SQL Server Management Studio 19

Python Libraries :
- pandas (Data Manipulation)
- pyodbc (Default DB-API for Microsoft SQL Server)
- create_engine from sqlalchemy (Engine or Connector to Connecting Python to SQL Server)
