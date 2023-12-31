using Stubble.Core.Builders;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/answerfile", async (HttpRequest request, [AsParameters] AnswerfileParams parameters) =>
{
    var stubble = new StubbleBuilder().Build();
    var (id, hostname) = parameters;
    var data = new AnswerfileViewModel(id, hostname, request);
    var template = await File.ReadAllTextAsync("./answerfile.mustache");
    // ensure unix line endings
    var output = (await stubble.RenderAsync(template, data)).Replace("\r\n", "\n");
    return Results.Text(output);
});
app.MapGet("/keys", async () => Results.Text(await File.ReadAllTextAsync("./gsham.keys")));

app.Run();

record AnswerfileParams(int id, string hostname)
{
}
