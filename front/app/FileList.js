import React, { Component } from 'react';

function File(props) {
  const link = props.api + props.root + '/' + props.file.path;
  return (
    <tr>
      <td>
        <a id={props.file.name} className="deco-none"
          target="_blank"
          href={link}>
          <img className="file-icon"
            src={props.file.icon}
            alt={props.file.alt}
            title={props.file.alt}
          />
          {props.file.name}
        </a>
      </td>
      <td className="hidden-md-down">
        <p className="text-muted">
          {props.file.alt}
        </p>
      </td>
      <td className="hidden-md-down">
        <p className="text-muted">
          {props.file.time}
        </p>
      </td>
      <td>
        <div className="btn-group" role="group">
          <button className="btn btn-secondary btn-sm" data-clipboard-text={link}
            type="button">
            Copy link
          </button>
          <a className="btn btn-secondary btn-sm"
            download={props.file.name}
            href={link}
            type="button">
            Download
          </a>
          <button className="btn btn-secondary btn-sm"
            type="button"
            onClick={props.deleteFile.bind(this, props.file)}>
            Delete
          </button>
        </div>
      </td>
    </tr>
  );
}

function Folder(props) {
  const link = 'folder/?path=' + props.folder.path;
  return (
    <tr>
      <td>
        <a className="deco-none folder-link"
          onClick={props.navigate.bind(this, props.folder.path)}>
          <img className="file-icon"
            src={props.api + '/static/img/folder.png'}
            alt="Folder"
            title="Folder"
          />
          {props.folder.name}
        </a>
      </td>
      <td className="hidden-md-down">
        <p className="text-muted">
          Folder
        </p>
      </td>
      <td className="hidden-md-down">
        <p className="text-muted">
          {props.folder.time}
        </p>
      </td>
      <td>
        <div className="btn-group" role="group">
          <button className="btn btn-secondary btn-sm" data-clipboard-text={props.api + link}
            type="button">
            Copy link
          </button>
          <a className="btn btn-secondary btn-sm"
            download={props.folder.name}
            href={link}
            type="button">
            Download
          </a>
          <button className="btn btn-secondary btn-sm"
            type="button"
            onClick={props.deleteFolder.bind(this, props.folder)}>
            Delete
          </button>
        </div>
      </td>
    </tr>
  );
}

class FileList extends Component {
  render() {
    var items = [];
    this.props.folders.forEach(folder => {
      items.push(<Folder
        api={this.props.api}
        navigate={this.props.navigate}
        deleteFolder={this.props.deleteFolder}
        folder={folder}
        key={folder.name} />
      );
    });
    this.props.files.forEach(file => {
      items.push(<File
        api={this.props.api}
        deleteFile={this.props.deleteFile}
        file={file}
        root={this.props.root}
        key={file.name} />
      );
    });
    return (
      <table className="mt-1 table">
        <thead>
          <tr>
            <th>Name</th>
            <th className="hidden-md-down">Type</th>
            <th className="hidden-md-down">Modified</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {items}
        </tbody>
      </table>
    );
  }
}

export default FileList;