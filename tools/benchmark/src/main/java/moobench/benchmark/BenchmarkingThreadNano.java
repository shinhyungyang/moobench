/***************************************************************************
 * Copyright 2014 Kieker Project (http://kieker-monitoring.net)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ***************************************************************************/

package moobench.benchmark;

import java.io.File;
import java.lang.management.GarbageCollectorMXBean;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import moobench.application.MonitoredClass;

/**
 * @author Jan Waller, Aike Sass, Christian Wulf, Shinhyung Yang
 */
public final class BenchmarkingThreadNano implements BenchmarkingThread {

  private final MonitoredClass mc;
  private final CountDownLatch doneSignal;
  private final int totalCalls;
  private final long methodTime;
  private final int recursionDepth;

  private final long[] executionTimes;

  private final MemoryMXBean memory;
  private final long[] usedHeapMemory;

  private final Path raplPath;
  private final long[] usedEnergy;

  private final long[] gcCollectionCountDiffs;
  private final List<GarbageCollectorMXBean> collector;

  public BenchmarkingThreadNano(final MonitoredClass mc, final int totalCalls,
      final long methodTime, final int recursionDepth, final CountDownLatch doneSignal) {
    this.mc = mc;
    this.doneSignal = doneSignal;
    this.totalCalls = totalCalls;
    this.methodTime = methodTime;
    this.recursionDepth = recursionDepth;
    // for monitoring execution times
    this.executionTimes = new long[totalCalls];
    // for monitoring memory consumption
    this.memory = ManagementFactory.getMemoryMXBean();
    this.usedHeapMemory = new long[totalCalls];
    // for monitoring energy consumption
    this.raplPath = Paths.get("/sys/class/powercap/intel-rapl:0", "energy_uj");
    this.usedEnergy = new long[totalCalls];
    // for monitoring the garbage collector
    this.gcCollectionCountDiffs = new long[totalCalls];
    this.collector = ManagementFactory.getGarbageCollectorMXBeans();
  }

  public String print(final int index, final String separatorString) {
    return String.format("%d%s%d%s%d%s%d",
        this.executionTimes[index], separatorString,
        this.usedHeapMemory[index], separatorString,
        this.gcCollectionCountDiffs[index], separatorString,
        this.usedEnergy[index]);
  }

  public final void run() {
    long start_ns;
    long stop_ns;
    long lastGcCount = this.computeGcCollectionCount();
    long currentGcCount;
    long start_uj;
    long stop_uj;

    for (int i = 0; i < this.totalCalls; i++) {
      start_uj = this.readCurrentEnergy();
      start_ns = this.getCurrentTimestamp();

      this.mc.monitoredMethod(this.methodTime, this.recursionDepth);

      stop_ns = this.getCurrentTimestamp();
      stop_uj = this.readCurrentEnergy();
      currentGcCount = this.computeGcCollectionCount();

      // save execution time
      this.executionTimes[i] = stop_ns - start_ns;
      // save consumed energy
      this.usedEnergy[i] = stop_uj - start_uj;
      // save heap memory
      this.usedHeapMemory[i] = this.memory.getHeapMemoryUsage().getUsed();
      // save gc collection count
      this.gcCollectionCountDiffs[i] = currentGcCount - lastGcCount;
      lastGcCount = currentGcCount;
      // print progress
      if ((i % 100000) == 0) {
        System.out.println(i); // NOPMD (System.out)
      }
    }

    this.doneSignal.countDown();
  }

  private long computeGcCollectionCount() {
    long count = 0;
    for (final GarbageCollectorMXBean bean : this.collector) {
      count += bean.getCollectionCount();
      // bean.getCollectionTime()
    }
    return count;
  }

  private long readCurrentEnergy() {
      long energy_uj = 0;
      try {
          energy_uj = Long.parseLong(Files.readAllLines(this.raplPath).get(0));
      } catch (Exception e) {
          System.err.println(e.toString());
      }
      return energy_uj;
  }

  private long getCurrentTimestamp() {
    // alternatively: System.currentTimeMillis();
    return System.nanoTime();
  }

}
