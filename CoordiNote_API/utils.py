def format_geojson_feature(row, geometry_column="geom"):
    """
    Converts a single database row into a GeoJSON Feature.

    :param row: Dictionary representing a single row from a database query.
    :param geometry_column: The name of the column containing the geometry in GeoJSON Binary format (default: "geom").
    :return: A GeoJSON Feature dictionary.
    """
    geojson = {
        "type": "Feature",
        "geometry": row.get(geometry_column),  # Geometry as GeoJSON
        "properties": {
            key: value for key, value in row.items() if key != geometry_column
        }
    }

    return geojson


def format_geojson_featurecollection(rows, geometry_column="geom"):
    """
    Formats a list of database rows as a GeoJSON FeatureCollection.

    :param rows: List of dictionaries representing rows from a database query.
    :param geometry_column: The name of the column containing the geometry in GeoJSON Binary format (default: "geom").
    :return: A GeoJSON FeatureCollection dictionary.
    """
    geojson = {
        "type": "FeatureCollection",
        "features": [format_geojson_feature(row, geometry_column) for row in rows]
    }

    return geojson

def format_geojson(rows, geometry_column="geom"):
    """
    Formats a list of database rows as a GeoJSON feature (single row) or FeatureCollection (multiple rows).

    :param rows: List of dictionaries representing rows from a database query.
    :param geometry_column: The name of the column containing the geometry in GeoJSON Binary format (default: "geom").
    :return: A GeoJSON FeatureCollection or a GeoJSON Feature dictionary.
    """
    if len(rows) > 1:
        geojson = format_geojson_featurecollection(rows, geometry_column)
    else:
        geojson = format_geojson_feature(rows[0], geometry_column)
    
    return geojson
