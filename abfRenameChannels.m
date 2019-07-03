% abfRenameChannels
% a small tool to help you batch-rename
% channels in ABF files 
% supports v1 ABF file formats
% 
% usage
% =====
%
% 1. create a file called channel_map.txt in the same
%    folder that abfRenameChannels exists. for an example,
%    look at the channel_map that comes with this
% 2. navigate to the folder with ABF files you want to
%    change the channels of
% 3. type "abfRenameChannels" in your MATLAB promp and
%    press enter.
%
% questions? bugs? abf@srinivas.gs
% Srinivas Gorur-Shandilya

function  abfRenameChannels()


% check for existance of channel_map.txt

file_loc = pathlib.join(fileparts(which(mfilename)),'channel_map.txt');

assert(exist(file_loc,'file') == 2,'channel_map.txt not found')

% read the channel map 
L = filelib.read(file_loc);

% validate the channel map 
old_name = cell(length(L),1);
new_name = cell(length(L),1);
for i = 1:length(L)
	arrow_pos = strfind(L{i},'>');
	assert(length(arrow_pos) == 1,'channel_map.txt is malformed')
	old_name{i} = flstring(strtrim(L{i}(1:arrow_pos-1)),10);
	new_name{i} = flstring(strtrim(L{i}(arrow_pos+1:end)),10);

	assert(~isempty(strrep(new_name{i},' ','')),'Malformed channel_map: at least one new name is empty')
	assert(~isempty(strrep(old_name{i},' ','')),'Malformed channel_map: at least one old name is empty')

end

% some global variables
machineF='ieee-le';
fid = 0;

% get all ABF files in current folder
all_files = dir('*.abf');

for i = 1:length(all_files)
	renameChannelsInABF(all_files(i).name);
end





;;     ;; ;;;;;;;; ;;       ;;;;;;;;  ;;;;;;;; ;;;;;;;;  
;;     ;; ;;       ;;       ;;     ;; ;;       ;;     ;; 
;;     ;; ;;       ;;       ;;     ;; ;;       ;;     ;; 
;;;;;;;;; ;;;;;;   ;;       ;;;;;;;;  ;;;;;;   ;;;;;;;;  
;;     ;; ;;       ;;       ;;        ;;       ;;   ;;   
;;     ;; ;;       ;;       ;;        ;;       ;;    ;;  
;;     ;; ;;;;;;;; ;;;;;;;; ;;        ;;;;;;;; ;;     ;; 

;;;;;;;;  ;;;;;;  ;;    ;;  ;;;;;;  
;;       ;;    ;; ;;;   ;; ;;    ;; 
;;       ;;       ;;;;  ;; ;;       
;;;;;;   ;;       ;; ;; ;;  ;;;;;;  
;;       ;;       ;;  ;;;;       ;; 
;;       ;;    ;; ;;   ;;; ;;    ;; 
;;        ;;;;;;  ;;    ;;  ;;;;;;  



	function renameChannelsInABF(file_name)

		[fid, messg] = fopen(file_name,'r+',machineF);
		if fid == -1
  			error(messg);
		end

		[fFileSignature,n] = fread(fid,4,'uchar=>char');
		if n ~= 4
			fclose(fid);
			error('something went wrong reading value(s) for fFileSignature');
		end

		% rewind
		fseek(fid,0,'bof');
		% transpose
		fFileSignature = fFileSignature';

		% one of the first checks must be whether file signature is valid
		switch fFileSignature
		 	case 'ABF ' % ** note the blank
		    	renameChannelsInABFv1();
		  	case 'ABF2'
		  		disp('ABF2 file')
		  		renameChannelsInABFv2();
		  otherwise
		    error('unknown or incompatible file signature. Send this file to abf@srinivas.gs');
		end

	end


	function renameChannelsInABFv1()

		if fseek(fid, 442,'bof') ~= 0
		  fclose(fid);
		  error('something went wrong locating the header');
		end

		sz = 160;

		channel_names = bytes2char(fread(fid,sz,'uchar'));

		for ii = 1:16
			this_channel_name = strtrim(channel_names(ii,:));
			for j = 1:length(old_name)
				if strcmp(this_channel_name,strtrim(old_name{j}))
					channel_names(ii,:) = new_name{j};
					break
				end
			end
		end

		b2 = char2bytes(channel_names);


		% rewind
		fseek(fid, 442,'bof');

		c = fwrite(fid,b2,'uchar',machineF);
		  
		if c == 0
			warning('Could not write to ABF file.')
		end
		fclose(fid);
	end

	function renameChannelsInABFv2()
		BLOCKSIZE=512;
		StringsSection = ReadSectionInfo(fid,220);
		fseek(fid,StringsSection.uBlockIndex*BLOCKSIZE,'bof');
		old_string = fread(fid,StringsSection.uBytes,'char');
		old_string = char(old_string)';

		new_string = old_string;

		% first, make sure that the new names are the exact same length as the old names
		for j = 1:length(old_name)
			old_name{j} = strtrim(old_name{j});
			new_name{j} = flstring(new_name{j},length(old_name{j}));
		end

		% do the actual replacement 
		for j = 1:length(old_name)
			new_string = strrep(new_string,old_name{j},new_name{j});
		end

		if length(new_string) == length(old_string)
		else
			disp('Something went wrong: ABF2 file! Send this file to Srinivas:')
			disp(length(new_string) == length(old_string))
			error('mismatched string length')
		end

		% write back to file
		bytes = char2bytes(new_string);

		% go back and overwrite
		fseek(fid,StringsSection.uBlockIndex*BLOCKSIZE,'bof');

		c = fwrite(fid,bytes,'uchar',machineF);
		      
		if c == 0
		    warning('Could not write to ABF file.')
		else
			disp('Wrote modified channel names')
		end

		fclose(fid);
	end



	function C = bytes2char(B)
	   temp = reshape(B,10,16);
	   C = char(temp');
	end

	function B = char2bytes(C)
	 	B = uint8(C)';
	 	B = double (B(:));
	end



	function SectionInfo = ReadSectionInfo(fid,offset)
		fseek(fid,offset,'bof');
		SectionInfo.uBlockIndex=fread(fid,1,'uint32');
		fseek(fid,offset+4,'bof');
		SectionInfo.uBytes=fread(fid,1,'uint32');
		fseek(fid,offset+8,'bof');
		SectionInfo.llNumEntries=fread(fid,1,'int64');
	end


end % end main function 




