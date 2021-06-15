// convolve a pdf and case vector
vector convolve(vector cases, vector pmf, int[] length) {
    int t = num_elements(cases);
    int pos = 1;
    vector[t] conv_cases = rep_vector(1e-5, t);
    for (s in 1:t) {
        vector[length[s]] seg_pmf = segment(pmf, pos, length[s]);
        conv_cases[s] += dot_product(cases[max(1, (s - length[s] + 1)):s],
                                     tail(seg_pmf, min(length[s], s)));
        pos = pos + 1;
    }
   return(conv_cases);
  }

vector calculate_pmfs(real[] delay_mean, real[] delay_sd, int[] max_delay) {
  int delays = num_elements(delay_mean);
  vector[sum(max_delay)] pmf;
  int pos = 1;
  for (s in 1:delays) {
    int delay_indexes[max_delay[s]];
    for (i in 1:max_delay[s]) {
      delay_indexes[i] = max_delay[s] - i;
    }
    segement(pmf, pos, max_delay[s]) =
        discretised_lognormal_pmf(delay_indexes, delay_mean[s],
                                   delay_sd[s], max_delay[s]);
    pos = pos + max_delay[s];
  }
  pmf = pmf + rep_vector(1e-8, sum(max_delay));
  return(pmf);
}

// convolve latent infections to reported (but still unobserved) cases
vector convolve_to_report(vector infections, vector pmfs,
                          int delays, int[] max_delay
                          int seeding_time) {
  int t = num_elements(infections);
  vector[t - seeding_time] reports;
  vector[t] unobs_reports = infections;
  int pos = 1;
  if (delays) {
    for (s in 1:delays) {
      int[t] seg_max_delay = max_delay[((s - 1) * t + 1):(s*t)];
      unobs_reports = convolve(
        unobs_reports, 
        segment(pmfs, pos, sum(seg_max_delay)),
        seg_max_delay);
      pos = pos + seg_max_delay;
    }
    reports = unobs_reports[(seeding_time + 1):t];
  }else{
    reports = infections[(seeding_time + 1):t];
  }
  return(reports);
}

void delays_lp(real[] delay_mean, real[] delay_mean_mean, real[] delay_mean_sd,
               real[] delay_sd, real[] delay_sd_mean, real[] delay_sd_sd, int weight){
    int delays = num_elements(delay_mean);
    if (delays) {
      for (s in 1:delays) {
       target += normal_lpdf(delay_mean[s] | delay_mean_mean[s], delay_mean_sd[s]) * weight;
       target += normal_lpdf(delay_sd[s] | delay_sd_mean[s], delay_sd_sd[s]) * weight;
     }
  }
}
