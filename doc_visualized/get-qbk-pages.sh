echo "Deleting any previous qbk and images directories..."
rm -rf qbk images

echo "Copying qbk from ../doc/qbk..."
cp -r ../doc/qbk .

echo "Copying images from ../doc/images"
cp -r ../doc/images .
