from reader import make_reader

reader = make_reader('data/reader.db')

feeds_to_add = []
with open('data/feeds.tsv', 'r', encoding='utf-8') as tsv_file:
    next(tsv_file)
    for line in tsv_file:
        url, name, description = line.strip().split('\t')
        feeds_to_add.append(url)

existing_feeds = {feed.url for feed in reader.get_feeds()}

for feed_url in feeds_to_add:
    if feed_url not in existing_feeds:
        print(f"Adding new feed: {feed_url}")
        reader.add_feed(feed_url)
    else:
        print(f"Feed already exists: {feed_url}")

reader.update_feeds()
