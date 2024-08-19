/**
 * ************************************************************************
 *  Copyright 2014 Kieker Project (http://kieker-monitoring.net)
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 * *************************************************************************
 */
package moobench.application;

import cp.swig.cloud_profiler;
import cp.swig.handler_type;
import cp.swig.log_format;

import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodHandles.Lookup;

/**
 * @author Jan Waller
 */
public final class MonitoredClassInstrumented implements MonitoredClass {

    private static final long ch_tin;

    private static final long ch_tout;

    static {
      try {
        System.loadLibrary("cloud_profiler");
      }
      catch (UnsatisfiedLinkError e) {
        System.err.println("ERROR: \"cloud_profiler\" native code library failed to load.\n" + e);
        System.exit(1);
      }
      System.out.println("SUCCESS: \"cloud_profiler\" native code library successfully loaded.");

      String cls = MethodHandles.lookup().lookupClass().getSimpleName();
      ch_tin  = cloud_profiler.openChannel(String.format("%-26s%5s", cls,  "tin"), log_format.ASCII, handler_type.NET_CONF);
      ch_tout = cloud_profiler.openChannel(String.format("%-26s%5s", cls, "tout"), log_format.ASCII, handler_type.NET_CONF);
    }

    /**
     * Default constructor.
     */
    public MonitoredClassInstrumented() {
      // measure before
      cloud_profiler.logTS(ch_tin, 0);
      try {
        return;
        // empty default constructor
      } finally {
        // measure after
        cloud_profiler.logTS(ch_tout, 0);
      }
    }

    public final long monitoredMethod(final long methodTime, final int recDepth) {
      // measure before
      cloud_profiler.logTS(ch_tin, recDepth);
      try {
        return monitoredMethod_Extracted(methodTime, recDepth);
      } finally {
        // measure after
        cloud_profiler.logTS(ch_tout, recDepth);
      }
    }

    private long monitoredMethod_Extracted(final long methodTime, final int recDepth) {
      if (recDepth > 1) {
        return this.monitoredMethod(methodTime, recDepth - 1);
      } else {
        final long exitTime = System.nanoTime() + methodTime;
        long currentTime;
        do {
          currentTime = System.nanoTime();
        } while (currentTime < exitTime);
        return currentTime;
      }
    }
}
