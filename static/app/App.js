import React, { Component } from 'react';
import axios from 'axios';

import SearchForm from './SearchForm';
import FileList from './FileList';
import Breadcrumbs from './Breadcrumbs';

function ErrorBox(props) {
  if (!props.error) {
    return null;
  }

  return (
    <p onClick={props.clicked} className="text-danger mt-1">
      {props.error}
    </p>
  );
}

class App extends Component {
  constructor(props) {
    super(props);
    this.api = this.props.api;
    axios.defaults.baseURL = this.api;
    this.upload = this.upload.bind(this);
    this.addFolder = this.addFolder.bind(this);
    this.drop = this.drop.bind(this);
    this.navigate = this.navigate.bind(this);
    this.fetchData = this.fetchData.bind(this);
    this.deleteFile = this.deleteFile.bind(this);
    this.deleteFolder = this.deleteFolder.bind(this);
    this.removeError = this.removeError.bind(this);
    this.scanFiles = this.scanFiles.bind(this);
    this.state = {
      folders: [],
      files: [],
      root: '',
      error: '',
      path: this.props.path,
    };
  }

  prevent(event) {
    event.preventDefault();
  }

  drop(event) {
    event.preventDefault();
    const items = event.dataTransfer.items;
    for (var i = 0; i < items.length; ++i) {
      const file = items[i].getAsFile();
      const item = items[i].webkitGetAsEntry();
      if (item && file) {
        this.scanFiles(item, file, false);
      }
    }
  }

  componentWillMount() {
    window.addEventListener("dragover", this.prevent);
    window.addEventListener("dragenter", this.prevent);
    window.addEventListener("dragleave", this.prevent);
    window.addEventListener("dragstart", this.prevent);
    window.addEventListener("drop", this.drop);
  }

  componentWillUnmount() {
    window.removeEventListener("dragover", this.prevent);
    window.removeEventListener("dragenter", this.prevent);
    window.removeEventListener("dragleave", this.prevent);
    window.removeEventListener("dragstart", this.prevent);
    window.removeEventListener("drop", this.drop);
  }

  componentDidMount() {
    this.fetchData();
  }

  upload(item, file) {
    const path = item.fullPath.substr(1);
    const filename = this.state.path ? this.state.path + '/' + path : path;
    axios.post('file', file, {
      headers: {
        'Filename': filename,
        'Content-Type': 'application/octet-stream'
      }
    })
    .then(res => {
      this.fetchData();
    })
    .catch(err => {
      this.setState({ error: 'Failed to upload file: ' + err});
    });
  }

  scanFiles(item, file) {
    var self = this;
    if (item.isDirectory) {
      self.addFolder(item.fullPath.substr(1));
      var directoryReader = item.createReader();
      directoryReader.readEntries(function(entries) {
        entries.forEach((entry) => {
          if (entry.isFile) {
            entry.file((file) => {
              self.scanFiles(entry, file)
            });
          } else if (entry.isDirectory) {
            self.scanFiles(entry, undefined);
          }
        });
      });
    } else if (item.isFile) {
      self.upload(item, file);
    }
  }

  deleteFile(file) {
    axios.delete('file', {
      data: file
    })
    .then(res => {
      const index = this.state.files.indexOf(file);
      this.setState({
        files: this.state.files.filter((_, i) => i !== index)
      });
    })
    .catch(err => {
      this.setState({ error: 'Failed to delete file: ' + err});
    });
  }

  deleteFolder(folder) {
    axios.delete('folder', {
      data: folder
    })
    .then(res => {
      const index = this.state.folders.indexOf(folder);
      this.setState({
        folders: this.state.folders.filter((_, i) => i !== index)
      });
    })
    .catch(err => {
      this.setState({ error: 'Failed to delete folder: ' + err});
    });
  }

  addFolder(folder) {
    axios.post('folder', {
      'path': this.state.path,
      'name': folder
    })
    .then(res => {
      this.fetchData();
    })
    .catch(err => {
      this.setState({ error: 'Failed to add folder: ' + err});
    });
  }

  fetchData() {
    axios.get('file/?path=' + this.state.path)
      .then(res => {
        this.setState({
          folders: res.data.folders,
          files: res.data.files,
          root: res.data.root
        });
      })
      .catch(err => {
        this.setState({ error: 'Failed to fetch data: ' + err});
      });
  }

  navigate(path, event) {
    event.preventDefault();
    this.setState({ path: path }, function() {
      this.fetchData();
    });
  }

  removeError() {
    this.setState({ error: '' });
  }

  render() {
    return (
      <div>
        <SearchForm
          addFolder={this.addFolder}
        />
        <ErrorBox
          error={this.state.error}
          clicked={this.removeError}
        />
        <Breadcrumbs
          navigate={this.navigate}
          path={this.state.path}
        />
        <FileList
          api={this.api}
          navigate={this.navigate}
          deleteFile={this.deleteFile}
          deleteFolder={this.deleteFolder}
          folders={this.state.folders}
          files={this.state.files}
          root={this.state.root}
        />
      </div>
    );
  }
}

export default App;
