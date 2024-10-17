package moobench.tools.receiver;

import kieker.analysis.generic.CountingStage;
import kieker.analysis.generic.source.rewriter.NoneTraceMetadataRewriter;
import kieker.analysis.generic.source.tcp.MultipleConnectionTcpSourceStage;
import kieker.common.record.IMonitoringRecord;

import teetime.framework.Configuration;

public class ReceiverConfiguration extends Configuration {

	public ReceiverConfiguration(final int inputPort, final int bufferSize) {
		MultipleConnectionTcpSourceStage source = new MultipleConnectionTcpSourceStage(inputPort, bufferSize, new NoneTraceMetadataRewriter());
		CountingStage<IMonitoringRecord> counting = new CountingStage<>(false, Integer.MAX_VALUE);
		
		connectPorts(source.getOutputPort(), counting.getInputPort());
	}
}
