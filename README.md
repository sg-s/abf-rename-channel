# abf-rename-channel

Small utility to rename channels in ABF files (both v1 & v2 supported)

## Installation 

The recommended way to install that is using my package manager:

```matlab
% copy and paste this into your MATLAB prompt 
urlwrite('http://srinivas.gs/install.m','install.m');
install -f sg-s/srinivas.gs_mtools
install -f sg-s/abf-rename-channel
```

## Usage 

1. create a file called `channel_map.txt` in the same folder that abfRenameChannels exists. for an example, look at the `channel_map.txt` that comes with this
2. navigate to the folder with ABF files you want to change the channels of
3. type "abfRenameChannels" in your MATLAB prompt and press enter.

## Limitations when working with ABFv1 files

Only 16 channels are supported, and no channel name can be more than 10 characters long. This is a limitation of the ABFv1 file format. 

## Limitations when working with ABFv2 files

When working with ABF v2 files, it is only possible to assign a new name that is as long as the old name. So, if you want to rename a channel called `IN 6` to `Electrode 6`, the new name will be truncated to the first four characters: `Elec`. So keep that in mind when you think of new names. 


## Help

questions? bugs? abf@srinivas.gs

## License

GPL v3