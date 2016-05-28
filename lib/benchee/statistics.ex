defmodule Benchee.Statistics do
  alias Benchee.Time

  @doc """
  Takes a job suite with job run times, returns a map representing the statistics
  of the job as follows:

  * average       - average run time of the job in μs (the lower the better)
  * ips           - iterations per second, how often can it be executed in one
                    second (the higher the better)
  * std_dev       - standard deviation, a measurement how much results vary
                    (the higher the more the results vary)
  * std_dev_ratio - standard deviation expressed as how much it is relative to
                    the average

  iex> times = [200, 400, 400, 400, 500, 500, 700, 900]
  iex> suite = %{jobs: [%{name: "My Job", run_times: times}]}
  iex> Benchee.Statistics.statistics(suite)
  [%{name: "My Job", average: 500.0, std_dev: 200.0, std_dev_ratio: 0.4, ips: 2000.0}]
  """
  def statistics(%{jobs: jobs}) do
    Enum.map jobs, fn(%{name: name, run_times: times}) ->
       Map.put Benchee.Statistics.job_statistics(times), :name, name
    end
  end

  @doc """
  Calculates statistical data based on a series of run times for a job
  in microseconds.

  iex> Benchee.Statistics.job_statistics([200, 400, 400, 400, 500, 500, 700, 900])
  %{average: 500.0, std_dev: 200.0, std_dev_ratio: 0.4, ips: 2000.0}
  """
  def job_statistics(run_times) do
    total_time            = Enum.sum(run_times)
    iterations            = Enum.count(run_times)
    average_time          = total_time / iterations
    iterations_per_second = iterations_per_second(iterations, total_time)
    standard_deviation    = standard_deviation(run_times, average_time, iterations)
    standard_dev_ratio    = standard_deviation / average_time

    %{
      average:       average_time,
      ips:           iterations_per_second,
      std_dev:       standard_deviation,
      std_dev_ratio: standard_dev_ratio,
    }
  end

  defp iterations_per_second(iterations, time_microseconds) do
    iterations / (Time.microseconds_to_seconds(time_microseconds))
  end

  defp standard_deviation(samples, average, iterations) do
    total_variance = Enum.reduce samples, 0,  fn(sample, total) ->
      total + :math.pow((sample - average), 2)
    end
    variance = total_variance / iterations
    :math.sqrt variance
  end
end