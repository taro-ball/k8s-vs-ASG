set -x # print variables
if [ "$test" == "k8s_apache_3" ]; then
warmup_url='80'
testing_url='80'
hpa_perc=70
warmup_min_threads=50
warmup_max_threads=60
warmup_cycle_sec=150
scaling_minutes=14
performance_sec=300
cluster_name="C888"
max_pods=6
max_nodes=3
fortio_options="-a -qps -1 -r 0.01 -loglevel Error"
fi

if [ "$test" == "k8s_taewa_3" ]; then
warmup_url='3000?n=20000'
testing_url='3000?n=20000'
hpa_perc=70
warmup_min_threads=15
warmup_max_threads=25
warmup_cycle_sec=90
scaling_minutes=14
performance_sec=300
cluster_name="C888"
max_pods=6
max_nodes=3
fortio_options="-a -qps -1 -r 0.01 -loglevel Error"
fi

if [ "$test" == "asg_apache_3" ]; then
warmup_url='80/test.html'
testing_url='80/test.html'
cpu_perc=70
warmup_min_threads=50
warmup_max_threads=60
warmup_cycle_sec=150
scaling_minutes=14
performance_sec=300
max_capacity=3
fortio_options="-a -qps -1 -r 0.01 -loglevel Error"
fi

if [ "$test" == "asg_taewa_3" ]; then
warmup_url='3000?n=20000'
testing_url='3000?n=20000'
cpu_perc=35
warmup_min_threads=15
warmup_max_threads=25
warmup_cycle_sec=90
scaling_minutes=14
performance_sec=300
max_capacity=3
fortio_options="-a -qps -1 -r 0.01 -loglevel Error"
fi

set +x