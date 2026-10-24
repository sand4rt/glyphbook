# Python source for consumers that generate their scripts with Nix.
''
  from urllib.parse import urlsplit


  class Websites:
      """Index catalog matchers once, without caching visited hosts or URLs."""

      def __init__(self, records):
          self.exact = {}
          self.wildcards = {}
          self.fallback = None
          for record in records:
              for domain in record["domains"]:
                  domain = domain.lower()
                  if domain == "*":
                      self.fallback = record
                  elif domain.startswith("*."):
                      self.wildcards.setdefault(domain[2:], record)
                  else:
                      self.exact.setdefault(domain, record)

      def get(self, host):
          """Resolve an exact host, longest wildcard suffix, then the fallback."""
          host = host.lower()
          if host in self.exact:
              return self.exact[host]
          while "." in host:
              host = host.partition(".")[2]
              if host in self.wildcards:
                  return self.wildcards[host]
          return self.fallback

      def get_url(self, url):
          """Resolve a URL (or bare host), ignoring credentials and port."""
          try:
              host = urlsplit(url if "://" in url else "//" + url).hostname or ""
          except ValueError:
              return self.fallback
          return self.get(host)
''
