partial class AnswerfileViewModel
{
    public int id { get; init; }
    public string hostname { get; init; }
    private HttpRequest request;

    public AnswerfileViewModel(int id, string hostname, HttpRequest request)
    {
        this.id = id;
        this.hostname = hostname;
        this.request = request;
    }

    public string HostPrefix => $"{request.Scheme}://{request.Host}{request.PathBase}";
}