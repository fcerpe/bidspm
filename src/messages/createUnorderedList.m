function list = createUnorderedList(list)
  %
  % turns a cell string or a structure into a string
  % that is an unordered list to print to the screen
  %
  % USAGE::
  %
  %  list = createUnorderedList(list)
  %
  % :param list: obligatory argument.
  % :type list: cell string or structure
  %
  %

  % (C) Copyright 2021 bidspm developers

  silenceOctaveWarning();

  prefix = '\n\t- ';

  if ischar(list)
    list = cellstr(list);
  end

  if iscell(list)

    for i = 1:numel(list)
      if isnumeric(list{i})
        list{i} = num2str(list{i});
      end
    end

    list = sprintf([prefix, strjoin(list, prefix), '\n']);

  elseif isstruct(list)

    output = '';
    fields = fieldnames(list);

    for i = 1:numel(fields)
      content = list.(fields{i});
      if ~iscell(content)
        content = {content};
      end

      for j = 1:numel(content)
        if isnumeric(content{j})
          content{j} = num2str(content{j});
        end
      end

      output = [output prefix fields{i} ': {' strjoin(content, ', ') '}'];
    end

    list = sprintf(output);

  end

end
