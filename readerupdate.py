from reader import make_reader

reader = make_reader('data/reader.db')

feeds = list(reader.get_feeds())
print(f"Total feeds found: {len(feeds)}")

pre_update_entries = {}
for feed in feeds:
    pre_update_entries[feed.url] = {entry.id for entry in reader.get_entries(feed=feed)}

try:
    reader.update_feeds()
    print("Feed update completed.")
except Exception as e:
    print(f"Feed update failed: {e}")

for feed in feeds:
    all_entries = list(reader.get_entries(feed=feed))
    new_items_count = sum(1 for entry in all_entries if entry.id not in pre_update_entries[feed.url])
    if new_items_count > 0:
        print(f"Feed '{feed.url}': {new_items_count} added items")
    else:
        print(f"No new items for '{feed.url}'")
