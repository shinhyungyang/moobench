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

import moobench.application.MonitoredClass;

/**
 * @author Jan Waller, Aike Sass, Christian Wulf
 */
public abstract class BenchmarkingThreadType implements BenchmarkingThread {

  protected final MonitoredClass mc;
  protected final CountDownLatch doneSignal;
  protected final int totalCalls;
  protected final long methodTime;
  protected final int recursionDepth;

  protected final long[] executionTimes;

  protected final MemoryMXBean memory;
  protected final long[] usedHeapMemory;

  protected final long[] gcCollectionCountDiffs;
  protected final List<GarbageCollectorMXBean> collector;

  protected long start_ns;
  protected long stop_ns;
  protected long lastGcCount;
  protected long currentGcCount;

  public BenchmarkingThreadType(final MonitoredClass mc, final int totalCalls,
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
    // for monitoring the garbage collector
    this.gcCollectionCountDiffs = new long[totalCalls];
    this.collector = ManagementFactory.getGarbageCollectorMXBeans();
  }

  protected long computeGcCollectionCount() {
    long count = 0;
    for (final GarbageCollectorMXBean bean : this.collector) {
      count += bean.getCollectionCount();
      // bean.getCollectionTime()
    }
    return count;
  }

  protected long getCurrentTimestamp() {
    // alternatively: System.currentTimeMillis();
    return System.nanoTime();
  }

}
