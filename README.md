# defold-biosim4
A Defold port of biosim4 to a native extension

Original biosim4 here: https://github.com/davidrmiller/biosim4

Please read the documents there for details about how biosim4 works.

Thanks to David Miller for sharing his work. And if you havent see his video, I highly recommend it.

https://www.youtube.com/watch?v=N3tRFayqVtk

This project also uses the excellent drawpixels nate extension: 

https://github.com/AGulev/drawpixels

Thanks to AGulev for this. 

## Biosim4.ini
To apply your own biosim4 properties:
1. Open data/biosim4.ini
2. Edit/Modify properties
3. Save the ini file and run the project

Its recommended keeping a backup of biosim4.ini if you are doing modifications.

## Limitations
Currently the port is not able to run multi-threaded. The numThreads property in the ini file will have no effect.

The main execution of the biosim simulation step is in a separate thread and pushes data out every step of operation into a data frame. This frame is then consumed by the Defold update and drawn on screen. This is a mutex locked operation so there may be slight jitters in frame rate.

## Futue
A number of additional features are being developed:
- imgui interface to update and control the sim
- a display of the neural structure of an agent - be able to pause, click and display an agent.
- some graphing of the population and generation stats (as provided by biosim4 at end of generation).

