
# phixer

An app to apply filters to the camera stream or to a stored photo.

This project is based on an earlier app named 'FilterCam'. I had to re-write all of the underlying filter and graphics code because Apple is dropping support for OpenGL(ES). 
I was originally using the nifty GPUImage library from Brad Larsen, but now I am using the built in CIFilter classes and using Metal for graphics processing. 
Also, I had to change the name because of an App Store conflict.


## Basic Functionality

One day, I'll get around to adding screenshots, but the basic set of functionality includes:


- browse all available filters, assign ratings, hide/show, add to favourites. You can also change some of the parameters (the scalar or colour ones) and see the effect
    - there are currently ~190 filters defined and an additional 500+ colour transforms available (lookup filters) that are based on available Photoshop presets
    - because of this, filters are assigned to 'categories', and users can hide ones they don't want to see
    - current categories are based on the source of the transform (e.g. Photoshop preset) or the Apple filter types. Expect these to be re-organsied drastically
- choose a sample image (used for browsing the filters). There are some built-in samples or you can use any photo
- choose a blend image, for those filters that combine multple images. There are some built-in blend images, or you can use any photo
- show the live camera feed and apply any filter. You can also save a photo with the filter applied (currently broken, will get to it eventually)
- there is a limited set of Style Transfer filters available - the usual group that is freely available (The Scream etc). I will be working on generating new ones, but that takes a lot of time and the tools are a bit lacking right now
- edit an image from your photo albums. 
  - I have added the basic ability to apply multiple filters and save the results. 
  - Right now it supports basic editing (exposure etc.), Style Transfer and application of any 'generic' filter (i.e. with no guiding from the UI). 
  - I also added help screens everywhere (very basic though) 
  - added features to preview effects and toggle between the original and the filtered image. You can also undo filters and reset the editing stack completely
- there is a simple and limited theme manager that lets you choose between a few themes (light, dark, red, blue). I plan on making this configurable eventually


## Pods Used
I make fairly extensive use of the following pods:

- Neon: very useful functions for laying out views relative to each other
- Chameleon: a set of 'flat' colours and associated utilities that I use to colour the UI
- iCarousel: a horizontally scrolling list that can contain images etc.
- SwiftyBeaver: logging utilities
- SwiftyJSON: JSON parsing
- Cosmos: a star rating widget

