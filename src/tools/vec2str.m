function [str,errMsg] = vec2str(vec,format,numericFlag,encloseFlag)
%vec2str Convert a vector/array/matrix of values into a comma-separated string
%   [str,errMsg] = vec2str(vec,format,numericFlag,encloseFlag)
%
%   Converts an input of unknown size/type into a compact single-line
%   comma-delimited string which is suitable for log files and table cells.
%   Accepts any dimension & combination of numbers, logicals, cells, 
%   Java/COM handles etc.
%
%   Inputs:
%     vec         - vector/array/matrix of values (mandatory input argument)
%                     Note: if vec is not numeric, it is always returned as-is
%                     Note: multi-dimentional (3D+) data is processed as 2D (may seem confusing at first)
%     format      - optional format/precision argument accepted by the num2str() function
%                     Note: for cell input, format is applied to each applicable cell element
%     numericFlag - optional flag indicating whether to keep scalar (non-vectors) numeric value as-is
%                     Note: default = 0 or false
%                     Note: overrides any format request
%                     Note: this flag is relevant only for numeric arrays/values
%     encloseFlag - optional flag indicating whether to enclose numeric vectors with [], cells with {}
%                     Note: default = 1 or true
%                     Note: scalar values are NEVER enclosed, regardless of encloseFlag
%
%   Outputs:
%     str - string representation of vec (or numeric value if numericFlag was requested)
%     errMsg - contains a non-empty string if an error occured during processing
%
%   Example:
%     str = vec2str('abcd')        => 'abcd' (string input always returns as-is)
%     str = vec2str(pi)            => '3.1416'
%     str = vec2str(pi,'=> %f <=') => '=> 3.141593 <=' (see SPRINTF for format explanation)
%     str = vec2str(pi,8)          => '3.1415927' (8 significant digits)
%     str = vec2str(pi,8,0)        => '3.1415927' (default numericFlag=0 so same result as above)
%     str = vec2str(pi,8,1)        => 3.14159265358979 (keeps numeric type, overrides format request)
%     str = vec2str(pi,[],[],1)    => '3.1416' (scalar values are NEVER enclosed with [])
%     str = vec2str(magic(3))      => '[8,1,6; 3,5,7; 4,9,2]'
%     str = vec2str(magic(3) > 4)  => '[true,false,true; false,true,true; false,true,false]'
%     str = vec2str(1:4)           => '[1,2,3,4]'
%     str = vec2str(1:4,[],[],1)   => '[1,2,3,4]' (default encloseFlag=1 so same result as above)
%     str = vec2str(1:4,[],[],0)   => '1,2,3,4'
%     str = vec2str({3,2:4,'ryt',NaN, -inf,sqrt(-i),{2,1},java.lang.String('ert')})
%         => '{3,[1x3 double],'ryt',NaN,-Inf,[0.707106781186548-0.707106781186548i],{1x2 cell},[1x1 java.lang.String]}'
%     str = vec2str({3,2:4,'ryt',NaN, -inf,sqrt(-i),{2,1},java.lang.String('ert')},3,'',0)
%         => ' '3','2 3 4','ryt','NaN','-Inf','0.707-0.707i',{1x2 cell},[1x1 java.lang.String]'
%
%   See also: num2str, int2str, sprintf

% Programmed by Yair M. Altman: altmany(at)gmail.com
% $Revision: 1.00 $  $Date: 2009/01/20 11:50:22 $

%   error(nargchk(1, 4, nargin, 'struct'))
  narginchk(1, 4);
  try
      % Clear any previous error message
      lasterr('');  %#ok

      % Numeric scalars/vectors
      if isnumeric(vec)

          % Initial conversion using num2str() (with format, if specified)
          if nargin>1 && ~isempty(format)
              str = num2str(vec,format);
          else
              str = num2str(vec);
          end

          % Convert 2D matrix rows into a single display line
          str = quenchStr(str);

          % Convert multiple consecutive spaces into commas (,)
          str = regexprep(strtrim(str),'  +',',');

          % Enclose with [] or return scalar numeric value as-is
          if nargin>2 && ~isempty(numericFlag) && numericFlag && numel(vec)==1  % change to <= if you also want [] to return numeric
              str = vec;
          elseif numel(vec) ~= 1 && (nargin<4 || encloseFlag)
              str = ['[' str ']'];
          else
              % regular processing - nothing left to do
          end

      % Cell arrays
      elseif iscell(vec)

          % Convert internal cell elements using format, if specified
          if nargin>1 && ~isempty(format)
              vec = cellfun(@(element)cell2str(element,format),vec,'uniform',0);  %#ok vec is used in evalc() below
          end

          % Start with the builtin display format
          str = evalc('disp(vec)');
          % Compress multi-line into a single line
          str = regexprep(str,{' *Col[^\n]*\n','\n'},'');
          % Convert consecutive spaces within elements into a single space (e.g.: '1 +  2i')
          str = regexprep(strtrim(str),{'  +([^\[{''])',' ([+-]) '},{' $1','$1'});
          % Convert multiple consecutive spaces into commas (,)
          str = regexprep(strtrim(str),'  +',',');
          % Remove [] enclosing numeric scalars
          str = regexprep(str,'\[(-?[\d.e-]+|-?Inf|NaN)\]','$1');

          % Enclose with {}, if encloseFlag was requested or implied
          if nargin<4 || encloseFlag
              str = ['{' str '}'];
          end

      % Numeric scalars/vectors
      elseif islogical(vec)

          % Convert 2D matrix rows into a single display line
          str = quenchStr(num2str(vec));

          % Convert multiple consecutive spaces into commas (,)
          str = regexprep(strtrim(str),'  +',',');

          % Convert 1/0 into 'true'/'false'
          str = regexprep(str,{'1','0'},{'true','false'});

          % Enclose with [] or return scalar numeric value as-is
          if nargin>2 && ~isempty(numericFlag) && numericFlag && numel(vec)==1  % change to <= if you also want [] to return numeric
              str = vec;
          elseif numel(vec) ~= 1 && (nargin<4 || encloseFlag)
              str = ['[' str ']'];
          else
              % regular processing - nothing left to do
          end

      else  % Java/COM arrays

          % TODO: needs better processing than this:
          str = strtrim(evalc('disp(vec)'));

      end  % if isnumeric vec
  catch
      % use evalc() to capture output into a Matlab variable
      str = strtrim(evalc('disp(vec)'));
  end
  errMsg = lasterr;  %#ok

  % Utility function to quench multi-dimentional data into a single line
  function str = quenchStr(str)
      numRows = size(str,1);
      if numRows > 1
          newStr = str(1,:);
          for rowIdx = 2 : size(str,1)
              newStr = [newStr '; ' str(rowIdx,:)];  %#ok
          end
          str = newStr(1:end);
      end
  end  % quenchStr

  % Utility function to convert a cell element to string based on specified format
  function element = cell2str(element,format)
      try
          element = num2str(element,format);
      catch
          % never mind...
      end
  end  % cell2str

end  % vec2str
  