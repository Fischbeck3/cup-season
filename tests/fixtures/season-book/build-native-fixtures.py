"""Embed actual synthetic RPC output only inside a DEBUG compilation guard."""
from pathlib import Path
root=Path(__file__).resolve().parents[3]
files=['squads','tie','upcoming','finished','home']
p=root/'apps/ios/CupSeason/Compete/SeasonBookFixtureJSON.swift'
p.write_text('// Synthetic local PostgreSQL RPC captures; regenerate with tests/fixtures/season-book/build-native-fixtures.py.\n#if DEBUG\nenum SeasonBookFixtureJSON {\n'+''.join('  static let '+f+' = #"'+(root/'tests/fixtures/season-book'/f'{f}.json').read_text().strip()+'"#\n' for f in files)+'}\n#endif\n')
