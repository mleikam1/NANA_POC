type SerpApiParams = Record<string, string | number | boolean | undefined | null>;

const SERP_API_BASE = 'https://serpapi.com/search.json';

function getApiKey(): string {
  const key = process.env.SERPAPI_KEY;
  if (!key) {
    throw new Error('Missing SERPAPI_KEY in functions environment.');
  }
  return key;
}

async function requestSerpApi(params: SerpApiParams): Promise<any> {
  const searchParams = new URLSearchParams();

  Object.entries({
    api_key: getApiKey(),
    hl: 'en',
    gl: 'us',
    ...params,
  }).forEach(([key, value]) => {
    if (value === undefined || value === null) return;
    searchParams.set(key, String(value));
  });

  const response = await fetch(`${SERP_API_BASE}?${searchParams.toString()}`);
  if (!response.ok) {
    throw new Error(`SerpApi request failed with ${response.status}`);
  }

  return response.json();
}

function normalizeCard(item: Record<string, any>, label: string): Record<string, any> {
  return {
    id:
      item.position?.toString() ??
      item.link ??
      item.title ??
      `${label.toLowerCase()}_${Math.random().toString(36).slice(2)}`,
    title: item.title ?? item.snippet ?? 'Untitled',
    subtitle:
      item.snippet ??
      (Array.isArray(item.extensions) ? item.extensions.join(' • ') : null) ??
      item.date ??
      item.source ??
      '',
    source: item.source ?? item.channel ?? item.profile_name ?? label,
    link: item.link ?? item.video_link ?? item.serpapi_link ?? '',
    imageUrl: item.thumbnail ?? item.serpapi_thumbnail ?? '',
    label,
    metadata: item,
  };
}

export async function fetchWeather(locationLabel: string): Promise<any> {
  const query = `What's the weather in ${locationLabel}?`;
  const response = await requestSerpApi({
    engine: 'google',
    q: query,
  });

  const answerBox = response.answer_box ?? {};
  return {
    location: answerBox.location ?? locationLabel,
    temperature: answerBox.temperature ?? '',
    unit: answerBox.unit ?? 'Fahrenheit',
    weather: answerBox.weather ?? '',
    humidity: answerBox.humidity ?? '',
    wind: answerBox.wind ?? '',
    date: answerBox.date ?? '',
    thumbnail: answerBox.thumbnail ?? '',
    forecast: (answerBox.forecast ?? []).slice(0, 5).map((item: any) => ({
      day: item.day ?? '',
      high: item.temperature?.high ?? '',
      low: item.temperature?.low ?? '',
      weather: item.weather ?? '',
    })),
    hourlyForecast: (answerBox.hourly_forecast ?? []).slice(0, 6).map((item: any) => ({
      time: item.time ?? '',
      temperature: item.temperature ?? '',
      weather: item.weather ?? '',
    })),
  };
}

export async function fetchLocalNews(locationLabel: string): Promise<any[]> {
  const response = await requestSerpApi({
    engine: 'google',
    q: `${locationLabel} local news`,
  });

  const localNews = response.local_news ?? response.news_results ?? [];
  return localNews.slice(0, 6).map((item: any) => normalizeCard(item, 'Local'));
}

export async function fetchRecipes(topicSeed: string): Promise<any[]> {
  const response = await requestSerpApi({
    engine: 'google',
    q: topicSeed || 'easy family dinner recipe',
  });

  const recipes = response.recipes_results ?? [];
  return recipes.slice(0, 6).map((item: any) => normalizeCard(item, 'Nourish'));
}

export async function fetchShortVideos(topicSeed: string): Promise<any[]> {
  const response = await requestSerpApi({
    engine: 'google_short_videos',
    q: topicSeed || 'calm home reset tips',
  });

  const shortVideos = response.short_videos ?? response.shorts_results ?? [];
  return shortVideos.slice(0, 6).map((item: any) => normalizeCard(item, 'Unwind'));
}

export async function fetchAiOverview(query: string): Promise<{
  aiOverviewTitle: string;
  aiOverviewBullets: string[];
}> {
  const response = await requestSerpApi({
    engine: 'google_ai_overview',
    q: query,
  });

  const candidates: string[] = [];
  const aiOverview = response.ai_overview ?? response.ai_overview_result ?? response;

  if (typeof aiOverview?.text === 'string') {
    candidates.push(aiOverview.text);
  }

  for (const item of aiOverview?.list ?? []) {
    if (typeof item?.text === 'string') candidates.push(item.text);
  }

  for (const item of aiOverview?.highlights ?? []) {
    if (typeof item?.title === 'string') candidates.push(item.title);
    if (typeof item?.snippet === 'string') candidates.push(item.snippet);
  }

  for (const item of aiOverview?.items ?? []) {
    if (typeof item?.title === 'string') candidates.push(item.title);
    if (typeof item?.snippet === 'string') candidates.push(item.snippet);
    if (typeof item?.text === 'string') candidates.push(item.text);
  }

  const bullets = candidates
    .map((item) => item.trim())
    .filter((item) => item.length > 0)
    .slice(0, 4);

  return {
    aiOverviewTitle: aiOverview?.title ?? "Today's nana note",
    aiOverviewBullets:
      bullets.length > 0
        ? bullets
        : [
            'Keep today centered on one useful action at a time.',
            'Use local utility first, then move into nourishing or calming content.',
          ],
  };
}
