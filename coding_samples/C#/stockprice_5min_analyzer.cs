using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using CsvHelper;
using OxyPlot;
using OxyPlot.Series;
using OxyPlot.WindowsForms;
using OxyPlot.Axes;

public class CandleChartForm : Form
{
    private Button loadButton;
    private PlotView plotView;
    private DateTimePicker datePicker;

    private List<CandleData> allCandles = new List<CandleData>();
    private string tickerSymbol = ""; // 銘柄コード（CSVファイル名から取得）

    public CandleChartForm()
    {
        datePicker = new DateTimePicker
        {
            Format = DateTimePickerFormat.Short,
            Left = 10,
            Top = 10
        };
        datePicker.ValueChanged += DatePicker_ValueChanged;

        loadButton = new Button { Text = "CSV読込", Left = 220, Top = 10 };
        loadButton.Click += LoadButton_Click;

        plotView = new PlotView
        {
            Left = 10,
            Top = 50,
            Width = 800,
            Height = 500
        };

        this.Controls.Add(datePicker);
        this.Controls.Add(loadButton);
        this.Controls.Add(plotView);
        this.Text = "5分足チャート";
        this.Width = 840;
        this.Height = 600;
    }

    private void LoadButton_Click(object sender, EventArgs e)
    {
        using var dialog = new OpenFileDialog();
        dialog.Filter = "CSV files (*.csv)|*.csv";
        if (dialog.ShowDialog() == DialogResult.OK)
        {
            // CSVファイル名（拡張子なし）を銘柄コードとしてセット
            tickerSymbol = Path.GetFileNameWithoutExtension(dialog.FileName);

            allCandles = LoadCandlesFromCsv(dialog.FileName);
            this.Text = $"{tickerSymbol} 5分足チャート"; // フォームタイトル更新
            UpdateChart(datePicker.Value.Date);
        }
    }

    private void DatePicker_ValueChanged(object sender, EventArgs e)
    {
        if (allCandles.Count > 0)
            UpdateChart(datePicker.Value.Date);
    }

    private void UpdateChart(DateTime targetDate)
    {
        var filtered = allCandles
            .Where(c =>
                c.Time.Date == targetDate ||
                (c.Time.Date == targetDate.AddDays(-1) && c.Time.TimeOfDay >= TimeSpan.FromHours(14))
            )
            .Where(c =>
                (c.Time.TimeOfDay >= TimeSpan.FromHours(9) && c.Time.TimeOfDay <= TimeSpan.FromHours(15.5)) ||
                (c.Time.Date == targetDate.AddDays(-1) && c.Time.TimeOfDay >= TimeSpan.FromHours(14))
            )
            .Where(c =>
                (c.Time.TimeOfDay < TimeSpan.FromHours(11.5) || c.Time.TimeOfDay >= TimeSpan.FromHours(12.5))
            )
            .OrderBy(c => c.Time)
            .ToList();

        if (filtered.Count == 0)
        {
            MessageBox.Show("指定日のチャートデータがありません。");
            return;
        }

        var plotModel = new PlotModel { Title = $"{tickerSymbol} {targetDate:yyyy/MM/dd} の5分足" };

        var categoryAxis = new CategoryAxis { Position = AxisPosition.Bottom, Angle = 45, Title = "時間" };
        var displayCandles = filtered.Where(c => c.Time.Date == targetDate).ToList();

        if (displayCandles.Count == 0)
        {
            MessageBox.Show("指定日のチャートデータがありません。");
            return;
        }

        categoryAxis.Labels.Add(" "); // 左余白
        foreach (var c in displayCandles)
        {
            categoryAxis.Labels.Add(c.Time.ToString("HH:mm"));
        }
        categoryAxis.Labels.Add(" "); // 右余白

        var priceAxis = new LinearAxis
        {
            Position = AxisPosition.Left,
            Minimum = displayCandles.Min(c => c.Low) * 0.995,
            Maximum = displayCandles.Max(c => c.High) * 1.005,
            Title = "価格",
            MajorGridlineStyle = LineStyle.Solid,
            MinorGridlineStyle = LineStyle.Dot
        };

        plotModel.Axes.Add(categoryAxis);
        plotModel.Axes.Add(priceAxis);

        var bullSeries = new CandleStickSeries { Color = OxyColors.Green, CandleWidth = 0.6 };
        var bearSeries = new CandleStickSeries { Color = OxyColors.Red, CandleWidth = 0.6 };

        for (int i = 0; i < displayCandles.Count; i++)
        {
            var c = displayCandles[i];
            var item = new HighLowItem(i + 1, c.High, c.Low, c.Open, c.Close); // +1 for left padding
            if (c.Close >= c.Open)
                bullSeries.Items.Add(item);
            else
                bearSeries.Items.Add(item);
        }

        // SMA(5)
        var sma5 = new LineSeries { Color = OxyColors.Red, Title = "SMA(5)", StrokeThickness = 1.0 };
        for (int i = 0; i < displayCandles.Count; i++)
        {
            var subset = filtered.Skip(i + filtered.IndexOf(displayCandles[0]) - 4).Take(5).ToList();
            if (subset.Count == 5)
            {
                double avg = subset.Average(c => c.Close);
                sma5.Points.Add(new DataPoint(i + 1, avg));
            }
        }

        // SMA(25)
        var sma25 = new LineSeries { Color = OxyColors.Green, Title = "SMA(25)", StrokeThickness = 1.0 };
        for (int i = 0; i < displayCandles.Count; i++)
        {
            var subset = filtered.Skip(i + filtered.IndexOf(displayCandles[0]) - 24).Take(25).ToList();
            if (subset.Count == 25)
            {
                double avg = subset.Average(c => c.Close);
                sma25.Points.Add(new DataPoint(i + 1, avg));
            }
        }

        plotModel.Series.Add(bullSeries);
        plotModel.Series.Add(bearSeries);
        plotModel.Series.Add(sma5);
        plotModel.Series.Add(sma25);

        // 15:30終値の青い横線を追加（15:25ローソク足の次のインデックスに描画）
        var candle1530 = allCandles.FirstOrDefault(c => c.Time.Date == targetDate && c.Time.TimeOfDay == TimeSpan.FromHours(15.5));
        if (candle1530 != null)
        {
            int index1525 = displayCandles.FindIndex(c => c.Time.TimeOfDay == TimeSpan.FromHours(15.25));
            if (index1525 >= 0)
            {
                int xIndexForLine = index1525 + 3; // 右にずらす

                var line1530 = new LineSeries
                {
                    Color = OxyColors.Blue,
                    StrokeThickness = 2,
                    Title = "15:30終値"
                };

                line1530.Points.Add(new DataPoint(xIndexForLine - 0.3, candle1530.Close));
                line1530.Points.Add(new DataPoint(xIndexForLine + 0.3, candle1530.Close));

                plotModel.Series.Add(line1530);
            }
        }

        // 09:00始値の青い横線を追加（09:00のローソク足の位置に描画）
        var candle0900 = displayCandles.FirstOrDefault(c => c.Time.TimeOfDay == TimeSpan.FromHours(9));
        if (candle0900 != null)
        {
            int index0900 = displayCandles.FindIndex(c => c.Time.TimeOfDay == TimeSpan.FromHours(9));
            if (index0900 >= 0)
            {
                int xIndexForLine = index0900; // +1 for 1-based axis

                var line0900 = new LineSeries
                {
                    Color = OxyColors.Blue,
                    StrokeThickness = 2,
                    Title = "09:00始値"
                };

                line0900.Points.Add(new DataPoint(xIndexForLine - 0.3, candle0900.Open));
                line0900.Points.Add(new DataPoint(xIndexForLine + 0.3, candle0900.Open));

                plotModel.Series.Add(line0900);
            }
        }

        plotView.Model = plotModel;
    }

    public class CandleData
    {
        public DateTime Time;
        public double Open;
        public double High;
        public double Low;
        public double Close;
    }

    private List<CandleData> LoadCandlesFromCsv(string path)
    {
        using var reader = new StreamReader(path);
        using var csv = new CsvReader(reader, CultureInfo.InvariantCulture);
        var candles = new List<CandleData>();

        csv.Read();
        csv.ReadHeader();

        while (csv.Read())
        {
            var timeStr = csv.GetField("time");
            var time = DateTime.Parse(timeStr, null, DateTimeStyles.RoundtripKind);

            candles.Add(new CandleData
            {
                Time = time,
                Open = double.Parse(csv.GetField("open")),
                High = double.Parse(csv.GetField("high")),
                Low = double.Parse(csv.GetField("low")),
                Close = double.Parse(csv.GetField("close"))
            });
        }

        return candles;
    }

    [STAThread]
    public static void Main()
    {
        Application.EnableVisualStyles();
        Application.Run(new CandleChartForm());
    }
}
