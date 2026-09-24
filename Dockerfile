# ─────────────────────────────────────────────────────────────────────────────
# Multi-stage Dockerfile for IntelliQ Smart Queue Backend
# Target: Render Free (Docker deployment)
# Runtime: ASP.NET Core 9 on Linux
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Build & Publish ─────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj first and restore (layer caching)
COPY backend/Smart_Queue/Smart_Queue.csproj backend/Smart_Queue/
RUN dotnet restore backend/Smart_Queue/Smart_Queue.csproj

# Copy Datasets_Clean (referenced by csproj as Content)
COPY Datasets_Clean/ Datasets_Clean/

# Copy the rest of the backend source
COPY backend/Smart_Queue/ backend/Smart_Queue/

# Publish in Release mode for linux-x64
RUN dotnet publish backend/Smart_Queue/Smart_Queue.csproj \
    -c Release \
    -o /app/publish \
    --no-restore

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Copy published output
COPY --from=build /app/publish .

# Render provides PORT env var (default 8080 on free tier)
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
ENV ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080

ENTRYPOINT ["dotnet", "Smart_Queue.dll"]
