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

file_loc = joinPath(fileparts(which(mfilename)),'channel_map.txt');

assert(exist(file_loc,'file') == 2,'channel_map.txt not found')

% read the channel map 
L = lineRead(file_loc);

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


% check existence of file
if ~exist(fn,'file')
  error(['could not find file ' fn]);
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
		  		error('This is a ABFv2+ file. This script wont work.')
		    	%renameChannelsInABFv2(file_name,old_name,new_name);
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



	function C = bytes2char(B)
	   temp = reshape(B,10,16);
	   C = char(temp');
	end

	function B = char2bytes(C)
	 	B = uint8(C)';
	 	B = double (B(:));
	end




end % end main function 




