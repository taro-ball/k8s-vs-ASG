set -x # print variables
if [ "$test" == "k8s_apache_3" ]; then
warmup_url='80'
testing_url='80'
hpa_perc=70
warmup_min_threads=25
warmup_max_threads=35
warmup_cycle_sec=120
scaling_minutes=10
performance_sec=300
cluster_name="C888"
max_pods=6
max_nodes=3
fi

if [ "$test" == "k8s_taewa_3" ]; then
warmup_url='3000?n=10000'
testing_url='3000?n=20000'
hpa_perc=70
warmup_min_threads=15
warmup_max_threads=25
warmup_cycle_sec=90
scaling_minutes=10
performance_sec=300
cluster_name="C888"
max_pods=6
max_nodes=3
fi

if [ "$test" == "asg_apache_3" ]; then
warmup_url='80/test.html'
testing_url='80/test.html'
cpu_perc=70
warmup_min_threads=65
warmup_max_threads=75
warmup_cycle_sec=90
scaling_minutes=15
performance_sec=300
max_capacity=3
fi

if [ "$test" == "asg_taewa_3" ]; then
warmup_url='3000?n=10000'
testing_url='3000?n=20000'
cpu_perc=35
warmup_min_threads=15
warmup_max_threads=25
warmup_cycle_sec=90
scaling_minutes=13
performance_sec=300
max_capacity=3
fi

set +x