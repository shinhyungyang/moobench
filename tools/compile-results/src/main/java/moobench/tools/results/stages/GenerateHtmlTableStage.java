package moobench.tools.results.stages;

import java.nio.file.Path;
import java.util.Set;

import moobench.tools.results.data.Measurements;
import moobench.tools.results.data.OrderedSet;
import moobench.tools.results.data.OutputFile;
import moobench.tools.results.data.TableInformation;
import teetime.stage.basic.AbstractTransformation;

public class GenerateHtmlTableStage extends AbstractTransformation<TableInformation, OutputFile> {

    private final Path tablePath;

    public GenerateHtmlTableStage(final Path tablePath) {
        this.tablePath = tablePath;
    }

    @Override protected void execute(final TableInformation tableInformation) throws Exception {
        String content = "<table>\n" + "  <tr>\n" + "    <th style=\"text-align: left;\">setup</th>\n" + "    <th style=\"text-align: left;\">run</th>\n"
                + "    <th style=\"text-align: center;\">mean</th>\n" + "    <th style=\"text-align: center;\">ci</th>\n"
                + "    <th style=\"text-align: center;\">sd</th>\n" + "    <th style=\"text-align: center;\">1.quartile</th>\n"
                + "    <th style=\"text-align: center;\">median</th>\n" + "    <th style=\"text-align: center;\">3.quartile</th>\n"
                + "    <th style=\"text-align: center;\">max</th>\n" + "    <th style=\"text-align: center;\">min</th>\n"
                + "  </tr>\n";
        final Set<String> currentKeySet = tableInformation.getCurrent().getMeasurements().keySet();
        final Set<String> previousKeySet = tableInformation.getPrevious().getMeasurements().keySet();
        final Set<String> completeKeySet = new OrderedSet<>();
        if (currentKeySet != null) {
            completeKeySet.addAll(currentKeySet);
        }
        if (previousKeySet != null) {
            completeKeySet.addAll(previousKeySet);
        }

        for (final String key : completeKeySet) {
            content += this.addMode(key, tableInformation.getCurrent().getMeasurements().get(key),
                    tableInformation.getPrevious().getMeasurements().get(key));
        }
        content += "</table>\n";
        this.outputPort.send(new OutputFile(this.tablePath.resolve(tableInformation.getName() + "-table.html"), content));
    }

    private String addMode(final String key, final Measurements current, final Measurements previous) {
        String result = "";
        if (current != null) {
            result = this.createRow(key, "current", current);
        }
        if (previous != null) {
            result += this.createRow(key, "past", previous);
        }
        return result;
    }

    private String createRow(final String key, final String run, final Measurements measurements) {
        final StringBuilder cells = new StringBuilder();
        cells.append(String.format("    <td style=\"text-align: left;\">%s</td>\n", key));
        cells.append(String.format("    <td style=\"text-align: left;\">%s</td>\n", run));

        this.addDouble(cells, measurements.getMean());
        this.addDouble(cells, measurements.getConvidence());
        this.addDouble(cells, measurements.getStandardDeviation());
        this.addDouble(cells, measurements.getLowerQuartile());
        this.addDouble(cells, measurements.getMedian());
        this.addDouble(cells, measurements.getUpperQuartile());
        this.addDouble(cells, measurements.getMin());
        this.addDouble(cells, measurements.getMax());

        return String.format("  <tr>\n%s  </tr>\n", cells.toString());
    }

    private StringBuilder addDouble(final StringBuilder cells, final Double value) {
        return cells.append(String.format("    <td style=\"text-align: right;\">%1.3f</td>\n", value));
    }

}
