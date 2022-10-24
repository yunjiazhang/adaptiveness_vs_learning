# PostgreSQL cardinality estimation quality

This script generates plots for visualizing how good the cardinality estimates
produced by postgresql's query optimizer are.  As an error measure, it uses
_q-error_, that is explained in [this research
paper](https://dl.acm.org/citation.cfm?id=2850594). It is basically
estimated_cardinality / actual_cardinality for overestimation, and the inverse
for underestimation.

The plots are generated as individual png files, and also in a single pdf file.

You can find example output in `output/example_output.pdf`. These plots were
generated using the [IMDb
dataset](ftp://ftp.fu-berlin.de/pub/misc/movies/database/frozendata/) and the
[JOB benchmark](http://dl.acm.org/citation.cfm?id=2850594).

Usage:
```bash
pip install -r requirements.txt # install dependencies
./cardinality_estimation_quality.py # view usage
./cardinality_estimation_quality.py 'host=localhost' /path/to/queries/files # run the queries, save the data collected from the explains, and generate the plots
./cardinality_estimation_quality.py output/query_results.pkl # generate the plots from the saved data
```

Ideas and contributions are welcome.
