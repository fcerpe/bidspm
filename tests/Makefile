clean: clean_local
	rm -rf bids-examples
	mkdir bids-examples && touch bids-examples/.gitkeep

clean_local:
	rm -rf dummyData/derivatives/bidspm-preproc/sub-*
	rm -rf dummyData/derivatives/bidspm-stats/sub-*
	rm -rf dummyData/bidspm-raw/sub-*
	rm -rf dummyData/derivatives/bidspm-stats/group
	rm -rf dummyData/derivatives/bidspm-*/jobs

data: clean
	sh createDummyDataSet.sh
	rm -rf bids-examples/
	git clone https://github.com/bids-standard/bids-examples.git --depth 1
	cp bids-examples/synthetic/dataset_description.json bids-examples/synthetic/derivatives/fmriprep
	touch bids-examples/.gitkeep

clean_openneuro:
	rm -rf openneuro/*

openneuro/ds001168/sub-01/ses-2/anat:
	mkdir openneuro -p
	datalad clone https://github.com/OpenNeuroDatasets/ds001168.git openneuro/ds001168
	cd openneuro/ds001168 && datalad get sub-01/ses-1/anat/* sub-01/ses-*/func/*fullbrain*
