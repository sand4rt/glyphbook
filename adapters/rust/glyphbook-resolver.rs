use std::convert::{TryFrom, TryInto};
use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::{self, BufRead, BufReader, Read, Seek, SeekFrom, Write};
use std::path::Path;

const MAGIC: &[u8; 8] = b"GLYPHIDX";
const HEADER_SIZE: u64 = 24;
const SLOT_SIZE: u64 = 32;

#[derive(Clone)]
struct Entry {
    key: Vec<u8>,
    offset: u64,
    length: u32,
}

fn hash(key: &[u8]) -> u64 {
    key.iter().fold(0xcbf29ce484222325, |hash, byte| {
        (hash ^ u64::from(*byte)).wrapping_mul(0x100000001b3)
    })
}

fn key(category: &str, name: &str) -> Vec<u8> {
    let mut result = Vec::with_capacity(category.len() + name.len() + 1);
    result.extend_from_slice(category.as_bytes());
    result.push(0x1f);
    result.extend_from_slice(name.as_bytes());
    result
}

fn normalize(category: &str, value: &str) -> String {
    if matches!(category, "file" | "directory" | "application") {
        value.to_owned()
    } else {
        value.to_ascii_lowercase()
    }
}

fn power_of_two_at_least(mut value: usize) -> usize {
    value = value.max(2);
    value.next_power_of_two()
}

fn build(records_path: &Path, matchers_path: &Path, index_path: &Path) -> io::Result<()> {
    let records = BufReader::new(File::open(records_path)?);
    let mut offsets = Vec::new();
    let mut offset = 0_u64;
    for line in records.split(b'\n') {
        let line = line?;
        if !line.is_empty() {
            offsets.push((offset, u32::try_from(line.len()).expect("record exceeds 4 GiB")));
        }
        offset += u64::try_from(line.len()).unwrap() + 1;
    }

    let mut entries = Vec::new();
    for line in BufReader::new(File::open(matchers_path)?).lines() {
        let line = line?;
        let mut fields = line.splitn(3, '\t');
        let category = fields.next().ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing matcher category"))?;
        let matcher = fields.next().ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing matcher"))?;
        let record = fields.next().ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing record number"))?
            .parse::<usize>().map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "invalid record number"))?;
        let (offset, length) = *offsets.get(record).ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "matcher record is missing"))?;
        entries.push(Entry { key: key(category, &normalize(category, matcher)), offset, length });
    }

    let capacity = power_of_two_at_least(entries.len() * 2);
    let mut slots: Vec<Option<Entry>> = vec![None; capacity];
    for entry in entries {
        let mut slot = (hash(&entry.key) as usize) & (capacity - 1);
        loop {
            match &slots[slot] {
                Some(existing) if existing.key == entry.key => break,
                Some(_) => slot = (slot + 1) & (capacity - 1),
                None => {
                    slots[slot] = Some(entry);
                    break;
                }
            }
        }
    }

    let mut index = File::create(index_path)?;
    index.write_all(MAGIC)?;
    index.write_all(&(capacity as u64).to_le_bytes())?;
    index.write_all(&(slots.iter().filter(|slot| slot.is_some()).count() as u64).to_le_bytes())?;
    let mut keys = Vec::new();
    for slot in slots {
        let mut bytes = [0_u8; SLOT_SIZE as usize];
        if let Some(entry) = slot {
            bytes[0..8].copy_from_slice(&hash(&entry.key).to_le_bytes());
            bytes[8..16].copy_from_slice(&entry.offset.to_le_bytes());
            bytes[16..20].copy_from_slice(&entry.length.to_le_bytes());
            bytes[20..28].copy_from_slice(&(keys.len() as u64).to_le_bytes());
            bytes[28..30].copy_from_slice(&(entry.key.len() as u16).to_le_bytes());
            keys.extend_from_slice(&entry.key);
        }
        index.write_all(&bytes)?;
    }
    index.write_all(&keys)?;
    Ok(())
}

struct Store {
    index: File,
    records: File,
    capacity: usize,
    keys_offset: u64,
}

impl Store {
    fn open(index_path: &Path, records_path: &Path) -> io::Result<Self> {
        let mut index = OpenOptions::new().read(true).open(index_path)?;
        let mut header = [0_u8; HEADER_SIZE as usize];
        index.read_exact(&mut header)?;
        if &header[0..8] != MAGIC {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "invalid Glyphbook index"));
        }
        let capacity = u64::from_le_bytes(header[8..16].try_into().unwrap()) as usize;
        Ok(Self {
            index,
            records: OpenOptions::new().read(true).open(records_path)?,
            capacity,
            keys_offset: HEADER_SIZE + (capacity as u64 * SLOT_SIZE),
        })
    }

    fn get(&mut self, category: &str, name: &str) -> io::Result<Option<String>> {
        let lookup = key(category, &normalize(category, name));
        let wanted_hash = hash(&lookup);
        let mut slot = (wanted_hash as usize) & (self.capacity - 1);
        for _ in 0..self.capacity {
            self.index.seek(SeekFrom::Start(HEADER_SIZE + slot as u64 * SLOT_SIZE))?;
            let mut bytes = [0_u8; SLOT_SIZE as usize];
            self.index.read_exact(&mut bytes)?;
            let stored_hash = u64::from_le_bytes(bytes[0..8].try_into().unwrap());
            if stored_hash == 0 {
                return Ok(None);
            }
            if stored_hash == wanted_hash {
                let key_offset = u64::from_le_bytes(bytes[20..28].try_into().unwrap());
                let key_length = u16::from_le_bytes(bytes[28..30].try_into().unwrap()) as usize;
                self.index.seek(SeekFrom::Start(self.keys_offset + key_offset))?;
                let mut stored_key = vec![0_u8; key_length];
                self.index.read_exact(&mut stored_key)?;
                if stored_key == lookup {
                    let offset = u64::from_le_bytes(bytes[8..16].try_into().unwrap());
                    let length = u32::from_le_bytes(bytes[16..20].try_into().unwrap()) as usize;
                    self.records.seek(SeekFrom::Start(offset))?;
                    let mut record = vec![0_u8; length];
                    self.records.read_exact(&mut record)?;
                    return String::from_utf8(record).map(Some).map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "record is not UTF-8"));
                }
            }
            slot = (slot + 1) & (self.capacity - 1);
        }
        Ok(None)
    }

    fn list(&mut self, category: &str) -> io::Result<Vec<String>> {
        let prefix = format!("{category}\x1f").into_bytes();
        let mut result = Vec::new();
        for slot in 0..self.capacity {
            self.index.seek(SeekFrom::Start(HEADER_SIZE + slot as u64 * SLOT_SIZE))?;
            let mut bytes = [0_u8; SLOT_SIZE as usize];
            self.index.read_exact(&mut bytes)?;
            if u64::from_le_bytes(bytes[0..8].try_into().unwrap()) == 0 { continue; }
            let key_offset = u64::from_le_bytes(bytes[20..28].try_into().unwrap());
            let key_length = u16::from_le_bytes(bytes[28..30].try_into().unwrap()) as usize;
            self.index.seek(SeekFrom::Start(self.keys_offset + key_offset))?;
            let mut stored_key = vec![0_u8; key_length];
            self.index.read_exact(&mut stored_key)?;
            if stored_key.starts_with(&prefix) {
                result.push(String::from_utf8(stored_key[prefix.len()..].to_vec()).map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "matcher is not UTF-8"))?);
            }
        }
        result.sort();
        Ok(result)
    }

    fn map(&mut self, category: &str) -> io::Result<Vec<(String, String)>> {
        let prefix = format!("{category}\x1f").into_bytes();
        let mut result = Vec::new();
        for slot in 0..self.capacity {
            self.index.seek(SeekFrom::Start(HEADER_SIZE + slot as u64 * SLOT_SIZE))?;
            let mut bytes = [0_u8; SLOT_SIZE as usize];
            self.index.read_exact(&mut bytes)?;
            if u64::from_le_bytes(bytes[0..8].try_into().unwrap()) == 0 { continue; }
            let key_offset = u64::from_le_bytes(bytes[20..28].try_into().unwrap());
            let key_length = u16::from_le_bytes(bytes[28..30].try_into().unwrap()) as usize;
            self.index.seek(SeekFrom::Start(self.keys_offset + key_offset))?;
            let mut stored_key = vec![0_u8; key_length];
            self.index.read_exact(&mut stored_key)?;
            if stored_key.starts_with(&prefix) {
                let offset = u64::from_le_bytes(bytes[8..16].try_into().unwrap());
                let length = u32::from_le_bytes(bytes[16..20].try_into().unwrap()) as usize;
                self.records.seek(SeekFrom::Start(offset))?;
                let mut record = vec![0_u8; length];
                self.records.read_exact(&mut record)?;
                result.push((
                    String::from_utf8(stored_key[prefix.len()..].to_vec()).map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "matcher is not UTF-8"))?,
                    String::from_utf8(record).map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "record is not UTF-8"))?,
                ));
            }
        }
        result.sort_by(|left, right| left.0.cmp(&right.0));
        Ok(result)
    }
}

fn website(store: &mut Store, host: &str) -> io::Result<Option<String>> {
    let host = host.to_ascii_lowercase()
        .split_once("://").map_or_else(|| host.to_ascii_lowercase(), |(_, rest)| rest.to_owned());
    let host = host.split(['/', '?', '#']).next().unwrap_or(&host).rsplit('@').next().unwrap_or(&host);
    let host = host.rsplit_once(':').filter(|(_, port)| port.chars().all(|character| character.is_ascii_digit())).map_or(host, |(name, _)| name);
    if let Some(record) = store.get("website", host)? { return Ok(Some(record)); }
    let mut labels = host.split('.').collect::<Vec<_>>();
    while labels.len() > 1 {
        labels.remove(0);
        if let Some(record) = store.get("website-wildcard", &labels.join("."))? { return Ok(Some(record)); }
    }
    store.get("website-fallback", "*")
}

fn file(store: &mut Store, path: &str, filetype: Option<&str>) -> io::Result<Option<String>> {
    let name = path.rsplit(['/', '\\']).next().unwrap_or(path);
    if let Some(record) = store.get("file", name)? { return Ok(Some(record)); }
    let parts = name.split('.').collect::<Vec<_>>();
    for index in 1..parts.len() {
        if let Some(record) = store.get("extension", &parts[index..].join("."))? { return Ok(Some(record)); }
    }
    if let Some(filetype) = filetype {
        if let Some(record) = store.get("editor-filetype", filetype)? { return Ok(Some(record)); }
    }
    store.get("default", "file")
}

fn usage() {
    eprintln!("usage: glyphbook-resolver --build RECORDS MATCHERS INDEX | --index INDEX --records RECORDS (get CATEGORY NAME | file PATH [FILETYPE] | website HOST | list CATEGORY)");
}

fn main() -> io::Result<()> {
    let arguments = env::args().skip(1).collect::<Vec<_>>();
    if arguments.first().map(String::as_str) == Some("--build") && arguments.len() == 4 {
        return build(Path::new(&arguments[1]), Path::new(&arguments[2]), Path::new(&arguments[3]));
    }
    if arguments.len() < 5 || arguments[0] != "--index" || arguments[2] != "--records" {
        usage();
        std::process::exit(2);
    }
    let mut store = Store::open(Path::new(&arguments[1]), Path::new(&arguments[3]))?;
    let command = arguments.get(4).map(String::as_str);
    match command {
        Some("get") if arguments.len() == 7 => {
            if let Some(record) = store.get(&arguments[5], &arguments[6])? { println!("{record}"); } else { std::process::exit(1); }
        }
        Some("file") if arguments.len() == 6 || arguments.len() == 7 => {
            if let Some(record) = file(&mut store, &arguments[5], arguments.get(6).map(String::as_str))? { println!("{record}"); } else { std::process::exit(1); }
        }
        Some("website") if arguments.len() == 6 => {
            if let Some(record) = website(&mut store, &arguments[5])? { println!("{record}"); } else { std::process::exit(1); }
        }
        Some("list") if arguments.len() == 6 => {
            if arguments[5] == "website" {
                let mut matchers = store.list("website")?;
                matchers.extend(store.list("website-wildcard")?.into_iter().map(|matcher| format!("*.{matcher}")));
                matchers.sort();
                for matcher in matchers { println!("{matcher}"); }
            } else {
                for matcher in store.list(&arguments[5])? { println!("{matcher}"); }
            }
        }
        Some("map") if arguments.len() == 6 => {
            for (matcher, record) in store.map(&arguments[5])? { println!("{matcher}\t{record}"); }
        }
        _ => { usage(); std::process::exit(2); }
    }
    Ok(())
}
