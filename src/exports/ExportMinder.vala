/*
* Copyright (c) 2018 (https://github.com/phase1geo/Outliner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using GLib;

public class ExportMinder : Object {

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, OutlineTable table ) {
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* opml = new Xml.Node( null, "opml" );
    string    expand_state;
    Xml.Node* body = export_body( table, out expand_state );
    opml->new_prop( "version", "2.0" );
    opml->add_child( export_head( Path.get_basename( fname ), expand_state ) );
    opml->add_child( body );
    doc->set_root_element( opml );
    doc->save_format_file( fname, 1 );
    delete doc;
    return( true );
  }

  /* Generates the header for the document */
  private static Xml.Node* export_head( string? title, string expand_state ) {
    Xml.Node* head = new Xml.Node( null, "head" );
    var now  = new DateTime.now_local();
    head->new_text_child( null, "title", (title ?? "Mind Map") );
    head->new_text_child( null, "dateCreated", now.to_string() );
    if( expand_state != "" ) {
      head->new_text_child( null, "expansionState", expand_state );
    }
    return( head );
  }

  /* Generates the body for the document */
  private static Xml.Node* export_body( OutlineTable table, out string expand_state ) {
    Xml.Node*  body    = new Xml.Node( null, "body" );
    Array<int> estate  = new Array<int>();
    for( int i=0; i<table.nodes.length; i++ ) {
      body->add_child( export_node( table.nodes.index( i ), ref estate ) );
    }
    expand_state = "";
    for( int i=0; i<estate.length; i++ ) {
      if( i > 0 ) {
        expand_state += ",";
      }
      expand_state += estate.index( i ).to_string();
    }
    return( body );
  }

  /* Traverses the node tree exporting XML nodes in OPML format */
  private static Xml.Node* export_node( Node node, ref Array<int> expand_state ) {
    Xml.Node* n = new Xml.Node( null, "outline" );
    n->new_prop( "text", node.name.text );
    /*
    if( is_leaf() && (_task_count > 0) ) {
      bool checked = _task_done > 0;
      node->new_prop( "checked", checked.to_string() );
    }
    */
    if( node.note.text != "" ) {
      n->new_prop( "note", node.note.text );
    }
    if( (node.children.length > 1) && node.expanded ) {
      expand_state.append_val( node.id );
    }
    for( int i=0; i<node.children.length; i++ ) {
      n->add_child( export_node( node.children.index( i ), ref expand_state ) );
    }
    return( n );
  }

  /*
   Reads the contents of an OPML file and creates a new document based on
   the stored information.
  */
  public static bool import( string fname, OutlineTable table ) {

    /* Read in the contents of the OPML file */
    var doc = Xml.Parser.parse_file( fname );
    if( doc == null ) {
      return( false );
    }

    /* Load the contents of the file */
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        Array<int>? expand_state = null;
        switch( it->name ) {
          case "head" :
            import_header( it, ref expand_state );
            break;
          case "body" :
            import_body( table, it, ref expand_state );
            break;
        }
      }
    }

    /* Delete the OPML document */
    delete doc;

    return( true );

  }

  /* Parses the OPML head block for information that we will use */
  private static void import_header( Xml.Node* n, ref Array<int>? expand_state ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "expansionState") ) {
        if( (it->children != null) && (it->children->type == Xml.ElementType.TEXT_NODE) ) {
          expand_state = new Array<int>();
          string[] values = n->children->get_content().split( "," );
          foreach (string val in values) {
            int intval = int.parse( val );
            expand_state.append_val( intval );
          }
        }
      }
    }
  }

  /* Imports the OPML data, creating a mind map */
  public static void import_body( OutlineTable table, Xml.Node* n, ref Array<int>? expand_state) {

    /* Clear the existing nodes */
    table.nodes.remove_range( 0, table.nodes.length );

    /* Load the contents of the file */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "outline") ) {
        table.nodes.append_val( import_node( table, it, ref expand_state ) );
      }
    }

  }

  /* Main method for importing an OPML <outline> into a node */
  public static Node import_node( OutlineTable table, Xml.Node* n, ref Array<int>? expand_state ) {

    Node node = new Node( table );

    /* Get the node name */
    string? t = n->get_prop( "text" );
    if( t != null ) {
      node.name.text = t;
    }

    /* Get the task information */
    string? c = n->get_prop( "checked" );
    if( c != null ) {
    /*
      _task_count = 1;
      _task_done  = bool.parse( t ) ? 1 : 0;
      propagate_task_info_up( _task_count, _task_done );
    */
    }

    /* Get the note information */
    string? o = n->get_prop( "note" );
    if( o != null ) {
      node.note.text = o;
    }

    /* Figure out if this node is folded */
    if( expand_state != null ) {
      node.expanded = false;
      for( int i=0; i<expand_state.length; i++ ) {
        if( expand_state.index( i ) == node.id ) {
          node.expanded = true;
          expand_state.remove_index( i );
          break;
        }
      }
    }

    /* Parse the child nodes */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "outline") ) {
        var child = import_node( table, it, ref expand_state );
        node.add_child( child );
      }
    }

    return( node );

  }


}
