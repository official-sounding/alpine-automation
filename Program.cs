var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/answerfile", async ([AsParameters] AnswerfileParams request) =>
{
    var (id, hostname) = request;
    var file = await File.ReadAllTextAsync("./answerfile.template");
    var output = file
        .Replace("{hostname}", hostname)
        .Replace("{id}", $"{id}");

    return Results.Text(output);
});
app.MapGet("/keys", async () => Results.Text(await File.ReadAllTextAsync("./gsham.keys")));

app.Run();

record AnswerfileParams(int id, string hostname)
{
}
