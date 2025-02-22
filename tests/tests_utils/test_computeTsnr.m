% (C) Copyright 2020 bidspm developers

function test_suite = test_computeTsnr %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_computeTsnr_basic()

  if isOctave
    % failure: 'nanmean' undefined near line 42, column 42
    % The 'nanmean' function belongs to the statistics package from Octave
    % Forge which seems to not be installed in your system.
    %
    % But installing packages does not seem to work now.
    return
  end

  opt = setOptions('MoAE');

  BIDS = bids.layout(opt.dir.raw);

  boldImage = bids.query(BIDS, 'data', 'suffix', 'bold', 'extension', '.nii');

  [tsnrImage, volTsnr] = computeTsnr(boldImage);

  assertEqual(size(volTsnr), [64, 64, 64]);
  assertEqual(spm_file(tsnrImage, 'filename'), 'sub-01_task-auditory_desc-tsnr_bold.nii');

end
